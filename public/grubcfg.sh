#!/bin/sh
# SPDX-License-Identifier: MIT
# macOS rescue helper. All writes require --apply and create a local backup.
set -eu
command -v python3 >/dev/null 2>&1 || { echo 'Install Python 3 (brew install python), then retry.' >&2; exit 1; }
exec python3 - "$@" <<'PY'
import argparse, datetime, difflib, hashlib, json, os, pathlib, plistlib
import re, shlex, shutil, stat, subprocess, sys, tempfile


def run(args):
    return subprocess.run(args, check=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE).stdout


def tool(name):
    for directory in ('/opt/homebrew/opt/e2fsprogs/sbin',
                      '/usr/local/opt/e2fsprogs/sbin'):
        candidate = pathlib.Path(directory) / name
        if candidate.is_file():
            return str(candidate)
    found = shutil.which(name)
    if not found:
        raise ValueError('Missing ' + name + '; run brew install e2fsprogs python first.')
    return found


def quoted(value):
    if any(c in str(value) for c in '\n\r\0'):
        raise ValueError('Invalid filename')
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"') + '"'


class Ext4:
    def __init__(self, device, check=True):
        self.device = device
        self.metadata = {}
        self.debugfs, self.fsck = tool('debugfs'), tool('e2fsck')
        if check:
            self.check()
        info = self.command('stats').decode()
        if check and (re.search(r'Filesystem state:\s+clean\s*$', info, re.M) is None
                or 'needs_recovery' in info):
            raise ValueError('Filesystem is not clean; boot Linux for filesystem repair first.')
        uuid = re.search(r'Filesystem UUID:\s+([0-9a-fA-F-]{36})\b', info)
        if not uuid:
            raise ValueError('Not an ext filesystem with a UUID.')
        self.identity = uuid[1]
        label = re.search(r'Filesystem volume name:\s+([^\n]+)', info)
        self.label = label[1].strip() if label else ''

    def command(self, command, write=False):
        return run([self.debugfs] + (['-w'] if write else []) + ['-R', command, self.device])

    def check(self):
        # No repair, journal replay, mounting or filesystem changes.
        run([self.fsck, '-f', '-n', self.device])

    def read(self, path):
        with tempfile.TemporaryDirectory(prefix='aurora-grub-') as tmp:
            out = pathlib.Path(tmp) / 'file'
            info = self.command('stat ' + quoted(path)).decode()
            if 'Type: regular' not in info:
                raise ValueError('Not a regular file: ' + path)
            if path not in self.metadata:
                mode = re.search(r'Mode:\s+(0[0-7]+)', info)[1]
                uid, gid = re.search(r'User:\s+(\d+)\s+Group:\s+(\d+)', info).groups()
                self.metadata[path] = {'mode': '0' + format(stat.S_IFREG | int(mode, 8), 'o'),
                                       'uid': uid, 'gid': gid}
            self.command('dump ' + quoted(path) + ' ' + quoted(out))
            return out.read_bytes()  # debugfs may report errors with exit status 0.

    def entries(self):
        data = self.command('ls -p /loader/entries').decode()
        return ['/loader/entries/' + name for name in re.findall(r'/([^/\n]+\.conf)/', data)
                if re.fullmatch(r'[A-Za-z0-9_.+-]+\.conf', name)]

    def write(self, path, data):
        with tempfile.TemporaryDirectory(prefix='aurora-grub-') as tmp:
            source = pathlib.Path(tmp) / 'file'
            source.write_bytes(data)
            self.command('rm ' + quoted(path), write=True)
            self.command('write ' + quoted(source) + ' ' + quoted(path), write=True)
            for field, value in self.metadata[path].items():
                self.command('set_inode_field ' + quoted(path) + ' ' + field + ' ' + value, write=True)
            if self.read(path) != data:
                raise ValueError('Write read-back failed: ' + path)


class Local:
    def __init__(self, path):
        self.path = pathlib.Path(path).absolute()
        if self.path.is_symlink() or not self.path.is_file():
            raise ValueError('--file must name a regular file, not a symlink.')
        self.identity = str(self.path)

    def read(self, path):
        return self.path.read_bytes()

    def write(self, path, data):
        original = self.path.stat()
        fd, name = tempfile.mkstemp(prefix='.grubcfg-', dir=self.path.parent)
        try:
            with os.fdopen(fd, 'wb') as out:
                out.write(data)
                out.flush()
                os.fsync(out.fileno())
                os.fchmod(out.fileno(), stat.S_IMODE(original.st_mode))
                if os.geteuid() == 0:
                    os.fchown(out.fileno(), original.st_uid, original.st_gid)
            os.replace(name, self.path)
        finally:
            if os.path.exists(name):
                os.unlink(name)

    def check(self):
        pass


def boot_config(store):
    paths = []
    for path in ('/grub/grub.cfg', '/grub2/grub.cfg'):
        try:
            text = store.read(path).decode('utf-8')
            paths.append((path, text))
        except (ValueError, FileNotFoundError):
            pass
    if len(paths) != 1:
        raise ValueError('Expected one /grub[2]/grub.cfg on the Linux boot partition.')
    return paths[0]


def unmounted(device):
    info = plistlib.loads(run(['/usr/sbin/diskutil', 'info', '-plist', device]))
    if info.get('WholeDisk') or info.get('Mounted') or info.get('MountPoint'):
        raise ValueError('The selected partition must be unmounted.')
    return info


def detect():
    # Enumerate physical GPT partitions, never APFS volumes or whole disks.
    tool('debugfs')
    tool('e2fsck')
    listing = plistlib.loads(run(['/usr/sbin/diskutil', 'list', '-plist', 'physical']))
    candidates, seen = [], set()
    linux_guid = '0FC63DAF-8483-4772-8E79-3D69D8477DE4'
    for disk in listing.get('AllDisksAndPartitions', []):
        for part in disk.get('Partitions', []):
            device = part.get('DeviceIdentifier', '')
            content = part.get('Content', '')
            if (not re.fullmatch(r'disk\d+s\d+', device) or device in seen
                    or (not content.lower().startswith('linux') and content.upper() != linux_guid)):
                continue
            seen.add(device)
            try:
                info = unmounted(device)
                # Probe only. A full clean-filesystem check follows selection.
                store = Ext4('/dev/' + device, check=False)
                path, text = boot_config(store)
                if store.label != 'AURORA_BOOT' and 'aurora' not in text.lower():
                    # Fedora also identifies its boot filesystem with this marker.
                    store.read('/grub2/aurora-boot-' + store.identity)
                candidates.append({'device': device, 'label': store.label,
                                   'uuid': store.identity, 'config': path,
                                   'bytes': info.get('TotalSize', part.get('Size', 0))})
            except (ValueError, OSError, subprocess.CalledProcessError):
                continue
    return candidates


def choose(candidates):
    def describe(item):
        return (item['device'] + ' — ' + item['label'] + ' — '
                + str(round(item['bytes'] / 1024**3, 2)) + ' GiB — ' + item['config'])
    if not candidates:
        raise ValueError('No unmounted Aurora boot partition found. Check that the installation disk is connected '
                         'and its Linux boot partition is unmounted. --device remains available for a manual target.')
    if len(candidates) == 1:
        print('Detected ' + describe(candidates[0]), flush=True)
        return candidates[0]['device']
    print('Multiple Aurora boot partitions found:', flush=True)
    for number, item in enumerate(candidates, 1):
        print(str(number) + ') ' + describe(item), flush=True)
    try:
        with open('/dev/tty', 'r+') as tty:
            tty.write('Choose installation number (empty cancels): ')
            tty.flush()
            answer = tty.readline().strip()
    except OSError:
        raise ValueError('Multiple installations need an interactive terminal or an explicit --device.') from None
    if not answer.isdigit() or not 1 <= int(answer) <= len(candidates):
        raise ValueError('No installation selected; nothing changed.')
    return candidates[int(answer)-1]['device']


def changed(text, action, value, env):
    count = 0

    def line(match):
        nonlocal count
        prefix, args = match.groups()
        # Materialize Fedora's kernelopts only from this installation's grubenv.
        if re.search(r'\$(?:kernelopts\b|\{kernelopts\})', args):
            if 'kernelopts' not in env:
                raise ValueError('kernelopts is indirect and grubenv could not be read.')
            args = re.sub(r'\$(?:kernelopts\b|\{kernelopts\})', lambda _: env['kernelopts'], args)
        # Refuse complex shell syntax instead of silently breaking quoted arguments.
        if any(c in args for c in "'\"\\;#") or args.rstrip().endswith('}'):
            raise ValueError('Complex kernel argument line; use edit instead of a preset.')
        words = args.split()
        if action in ('verbose', 'diagnostic'):
            remove = {'quiet', 'rhgb', 'splash', 'loglevel', 'ignore_loglevel',
                      'systemd.show_status', 'plymouth.enable'}
            words = [w for w in words if w.split('=', 1)[0] not in remove]
            words += (['loglevel=7', 'ignore_loglevel', 'systemd.show_status=1',
                       'plymouth.enable=0'] if value == 'on' or action == 'diagnostic' else ['quiet'])
            if action == 'diagnostic':
                efi = [flag for word in words if word.startswith('efi=')
                       for flag in word[4:].split(',') if flag and flag != 'debug']
                words = [w for w in words if w.split('=', 1)[0] not in
                         ('console', 'initcall_debug', 'efi')]
                words += ['console=tty0', 'initcall_debug', 'efi=' + ','.join(efi + ['debug'])]
        else:
            key = value.split('=', 1)[0] if action in ('add', 'remove') else 'nomodeset'
            if not re.fullmatch(r'[A-Za-z0-9_.-]+', key):
                raise ValueError('Invalid kernel argument name.')
            words = [w for w in words if w.split('=', 1)[0] != key]
            if action == 'add':
                if not re.fullmatch(r'[A-Za-z0-9_.=,:/+@%-]+', value):
                    raise ValueError('Use edit for a quoted or complex argument value.')
                words.append(value)
            elif action == 'nomodeset' and value == 'on':
                words.append('nomodeset')
        count += 1
        return prefix + ' '.join(words)

    pattern = r'(?m)^([ \t]*(?:linux(?:efi)?[ \t]+\S+[ \t]+|options[ \t]+))([^\r\n]+)$'
    result = re.sub(pattern, line, text)
    return result, count


def apply(store, before, after, directory):
    backup = pathlib.Path(directory).absolute()
    backup.mkdir(mode=0o700, parents=False, exist_ok=False)
    manifest = {'identity': store.identity, 'files': {}}
    for index, (path, data) in enumerate(before.items()):
        name = str(index) + '.before'
        (backup / name).write_bytes(data)
        manifest['files'][path] = {'backup': name, 'sha256': hashlib.sha256(data).hexdigest()}
    (backup / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('Backup:', backup, flush=True)
    written = []
    try:
        for path, data in after.items():
            if store.read(path) != before[path]:
                raise ValueError('File changed since preview: ' + path)
            written.append(path)
            store.write(path, data)
            if store.read(path) != data:
                raise ValueError('Read-back mismatch: ' + path)
        store.check()
    except BaseException:
        print('Write failed; restoring changed files from ' + str(backup), file=sys.stderr)
        for path in reversed(written):
            store.write(path, before[path])
        store.check()
        raise


def main():
    parser = argparse.ArgumentParser(prog='grubcfg.sh', description='Edit Aurora GRUB from macOS. Preview by default; --apply writes with backup.')
    target = parser.add_mutually_exclusive_group()
    target.add_argument('--device', help='Override automatic detection with an unmounted boot partition, e.g. disk0s5')
    target.add_argument('--file', help='An already accessible grub.cfg or BLS .conf file')
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--backup-dir', default='grubcfg-backup-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
    parser.add_argument('action', choices=['show', 'edit', 'verbose', 'diagnostic', 'nomodeset', 'add', 'remove', 'restore'])
    parser.add_argument('value', nargs='?')
    args = parser.parse_args()
    if args.action in ('verbose', 'nomodeset') and args.value not in ('on', 'off'):
        parser.error(args.action + ' needs on or off')
    if args.action in ('add', 'remove', 'restore') and not args.value:
        parser.error(args.action + ' needs a value')
    env = {}
    if not args.file:
        if sys.platform != 'darwin' or os.geteuid() != 0:
            raise ValueError('Automatic detection and --device require macOS and sudo.')
        device = args.device.removeprefix('/dev/') if args.device else choose(detect())
        if not re.fullmatch(r'disk\d+s\d+', device):
            raise ValueError('Select a partition such as disk0s5, never a whole disk.')
        unmounted(device)
        store = Ext4('/dev/' + device)
        config, cfg = boot_config(store)
        paths = [config]
        if re.search(r'^\s*blscfg\b', cfg, re.M):
            paths = store.entries()
            if not paths:
                raise ValueError('BLS configuration found but no loader/entries/*.conf files.')
            try:
                raw = store.read('/grub2/grubenv').decode()
                env = dict(re.findall(r'^([A-Za-z_]+)=(.*)$', raw, re.M))
            except (ValueError, FileNotFoundError):
                pass
    else:
        store = Local(args.file)
        paths = [str(store.path)]
    before = {path: store.read(path) for path in paths}
    after = {}
    if args.action == 'restore':
        backup = pathlib.Path(args.value)
        manifest = json.loads((backup / 'manifest.json').read_text())
        if manifest['identity'] != store.identity:
            raise ValueError('Backup belongs to another filesystem/file.')
        for path, record in manifest['files'].items():
            if path not in before or not re.fullmatch(r'\d+\.before', record['backup']):
                raise ValueError('Backup paths differ from this installation.')
            data = (backup / record['backup']).read_bytes()
            if hashlib.sha256(data).hexdigest() != record['sha256']:
                raise ValueError('Backup checksum mismatch.')
            after[path] = data
    for path, data in before.items():
        if args.action == 'restore':
            continue
        text = data.decode('utf-8')
        if args.action == 'show':
            print('--- ' + path + '\n' + text)
            continue
        if args.action == 'edit':
            with tempfile.TemporaryDirectory(prefix='aurora-grub-edit-') as tmp:
                candidate = pathlib.Path(tmp) / pathlib.Path(path).name
                candidate.write_bytes(data)
                # Python itself reads this embedded program from stdin.
                with open('/dev/tty', 'r+') as tty:
                    subprocess.run(shlex.split(os.environ.get('EDITOR', 'vi')) + [str(candidate)],
                                   stdin=tty, stdout=tty, stderr=tty, check=True)
                after[path] = candidate.read_bytes()
            if not after[path].strip():
                raise ValueError('Refusing an empty boot configuration.')
        else:
            result, count = changed(text, args.action, args.value, env)
            if not count:
                raise ValueError('No kernel/options lines found: ' + path)
            after[path] = result.encode()
    after = {p: data for p, data in after.items() if data != before[p]}
    for path, data in after.items():
        print(''.join(difflib.unified_diff(before[path].decode().splitlines(True),
                                         data.decode().splitlines(True), path, path + ' (new)')))
    if not after:
        if args.action != 'show':
            print('No changes.')
    elif not args.apply:
        print('Preview only. Repeat with --apply to save these changes.')
    else:
        if not args.file:
            unmounted(device)
            # Do not write to another filesystem if disks were detached/reused.
            current = Ext4('/dev/' + device)
            if current.identity != store.identity:
                raise ValueError('Selected filesystem changed during editing; nothing written.')
        apply(store, {p: before[p] for p in after}, after, args.backup_dir)
        print('Saved and verified. No reboot performed. Kernel updates may regenerate these files.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError) as error:
        detail = error.stderr.decode(errors='replace').strip() if isinstance(error, subprocess.CalledProcessError) else str(error)
        sys.exit('grubcfg.sh: ' + detail)
PY
