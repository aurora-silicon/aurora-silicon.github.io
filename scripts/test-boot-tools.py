#!/usr/bin/env python3
"""Exercise boot helpers without touching NVRAM or a physical disk."""
import contextlib
import io
import json
import pathlib
import plistlib
import shutil
import subprocess
import tempfile
import types
import unittest
from unittest.mock import patch, mock_open

ROOT = pathlib.Path(__file__).resolve().parents[1]


def load(name):
    source = (ROOT / 'public' / (name + '.sh')).read_text()
    source = source.split("<<'PY'\n", 1)[1].rsplit('\nPY', 1)[0]
    module = types.ModuleType(name)
    exec(compile(source, name, 'exec'), module.__dict__)
    return module


grub, verbose = load('grubcfg'), load('verbose')
CFG = 'menuentry "Aurora" {\n  linux /vmlinuz root=UUID=abc ro quiet splash loglevel=3\n  initrd /initramfs\n}\n'


class Arguments(unittest.TestCase):
    def test_verbose_preserves_root_and_initrd(self):
        text, count = grub.changed(CFG, 'verbose', 'on', {})
        self.assertEqual(count, 1)
        self.assertIn('root=UUID=abc ro loglevel=7 ignore_loglevel', text)
        self.assertNotIn('quiet', text)
        self.assertIn('initrd /initramfs', text)
        self.assertEqual(grub.changed(text, 'verbose', 'on', {})[0], text)

    def test_bls_expands_kernelopts(self):
        text, count = grub.changed('title Linux\nlinux /vmlinuz\noptions $kernelopts\n',
                                   'verbose', 'on', {'kernelopts': 'root=UUID=abc quiet rhgb'})
        self.assertEqual(count, 1)
        self.assertIn('options root=UUID=abc loglevel=7', text)
        self.assertNotIn('$kernelopts', text)
        with self.assertRaises(ValueError):
            grub.changed('options $kernelopts\n', 'verbose', 'on', {})

    def test_off_add_remove_and_nomodeset(self):
        text = grub.changed(CFG, 'verbose', 'off', {})[0]
        self.assertIn('root=UUID=abc ro quiet', text)
        text = grub.changed(text, 'nomodeset', 'on', {})[0]
        self.assertIn('nomodeset', text)
        text = grub.changed(text, 'nomodeset', 'off', {})[0]
        self.assertNotIn('nomodeset', text)
        text = grub.changed(text, 'add', 'loglevel=5', {})[0]
        self.assertIn('loglevel=5', text)
        text = grub.changed(text, 'remove', 'loglevel', {})[0]
        self.assertNotIn('loglevel=', text)

    def test_complex_line_refused(self):
        for line in ['options root="a b" quiet\n', 'options root=x; reboot\n']:
            with self.assertRaises(ValueError):
                grub.changed(line, 'verbose', 'on', {})

    def test_argumentless_kernel_does_not_consume_next_line(self):
        text = 'linux /vmlinuz\ninitrd /initramfs\n'
        self.assertEqual(grub.changed(text, 'verbose', 'on', {}), (text, 0))

    def test_diagnostic_all_options_and_existing_efi_flags(self):
        text = CFG.replace('loglevel=3', 'loglevel=3 console=ttyAMA0 efi=novamap,debug initcall_debug=0')
        text, count = grub.changed(text, 'diagnostic', None, {})
        self.assertEqual(count, 1)
        for flag in ['console=tty0', 'loglevel=7', 'ignore_loglevel', 'initcall_debug',
                     'systemd.show_status=1', 'plymouth.enable=0', 'efi=novamap,debug']:
            self.assertIn(flag, text)
        for flag in ['quiet', 'splash', 'console=ttyAMA0', 'initcall_debug=0']:
            self.assertNotIn(flag, text)
        self.assertEqual(grub.changed(text, 'diagnostic', None, {})[0], text)

    def test_diagnostic_bls_preserves_root_and_kernel(self):
        text, count = grub.changed('title Fedora\nlinux /vmlinuz-36\noptions $kernelopts\n',
                                   'diagnostic', None, {'kernelopts': 'root=UUID=abc rootflags=subvol=root quiet rhgb'})
        self.assertEqual(count, 1)
        self.assertIn('linux /vmlinuz-36\n', text)
        self.assertIn('root=UUID=abc rootflags=subvol=root', text)
        self.assertIn('efi=debug', text)

    def test_nvram_quotes_and_other_arguments(self):
        value = 'foo="keep -v inside quotes"  debug=0x100 -v keepsyms=1 -v'
        off = verbose.toggle(value, False)
        self.assertEqual(off, 'foo="keep -v inside quotes"  debug=0x100  keepsyms=1 ')
        self.assertEqual(verbose.toggle(off, True), off + '-v')

    def test_nvram_data_and_literal_percent_roundtrip(self):
        captured = []

        def setter(command, **kwargs):
            self.assertEqual(command[:3], ['/usr/sbin/nvram', '-x', '-f'])
            captured.append(plistlib.loads(pathlib.Path(command[3]).read_bytes()))

        for before in ['foo=%20 -v', b'foo=%20 -v']:
            after = b'foo=%20 ' if isinstance(before, bytes) else 'foo=%20 '
            with patch.object(verbose.sys, 'platform', 'darwin'), \
                 patch.object(verbose.sys, 'argv', ['verbose.sh', 'off']), \
                 patch.object(verbose.os, 'geteuid', return_value=0), \
                 patch.object(verbose, 'read_args', side_effect=[before, before, after]), \
                 patch.object(verbose.subprocess, 'run', side_effect=setter), \
                 contextlib.redirect_stdout(io.StringIO()):
                verbose.main()
            self.assertEqual(captured[-1], {'boot-args': after})

    def test_nvram_concurrent_change_aborts(self):
        with patch.object(verbose.sys, 'platform', 'darwin'), \
             patch.object(verbose.sys, 'argv', ['verbose.sh', 'on']), \
             patch.object(verbose.os, 'geteuid', return_value=0), \
             patch.object(verbose, 'read_args', side_effect=['foo=1', 'foo=2']), \
             patch.object(verbose.subprocess, 'run') as setter, \
             contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(ValueError):
                verbose.main()
            setter.assert_not_called()


class Files(unittest.TestCase):
    def test_preview_apply_restore(self):
        with tempfile.TemporaryDirectory() as tmp:
            file = pathlib.Path(tmp) / 'grub.cfg'
            file.write_text(CFG)
            file.chmod(0o640)
            command = ['sh', str(ROOT / 'public/grubcfg.sh'), '--file', str(file)]
            preview = subprocess.check_output(command + ['verbose', 'on'], text=True)
            self.assertIn('Preview only', preview)
            self.assertEqual(file.read_text(), CFG)
            backup = pathlib.Path(tmp) / 'backup'
            subprocess.run(command + ['--apply', '--backup-dir', str(backup), 'verbose', 'on'],
                           check=True, stdout=subprocess.DEVNULL)
            self.assertNotEqual(file.read_text(), CFG)
            self.assertEqual(file.stat().st_mode & 0o777, 0o640)
            subprocess.run(command + ['--apply', '--backup-dir', str(backup) + '-undo', 'restore', str(backup)],
                           check=True, stdout=subprocess.DEVNULL)
            self.assertEqual(file.read_text(), CFG)

    def test_failure_rolls_back(self):
        class Failing(grub.Local):
            fail = True

            def write(self, path, data):
                super().write(path, data)
                if self.fail:
                    self.fail = False
                    raise OSError('injected write failure')

        with tempfile.TemporaryDirectory() as tmp:
            file = pathlib.Path(tmp) / 'grub.cfg'
            file.write_text(CFG)
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(OSError):
                    grub.apply(Failing(file), {str(file): CFG.encode()}, {str(file): b'changed'}, tmp + '/backup')
            self.assertEqual(file.read_text(), CFG)

    def test_mounted_and_whole_devices_rejected(self):
        with patch.object(grub.sys, 'platform', 'darwin'), patch.object(grub.os, 'geteuid', return_value=0):
            for device, info in [('disk0', {}), ('disk0s5', {'Mounted': True})]:
                with patch.object(grub.sys, 'argv', ['grubcfg.sh', '--device', device, 'show']), \
                     patch.object(grub, 'run', return_value=plistlib.dumps(info)), \
                     patch.object(grub, 'Ext4') as opened:
                    with self.assertRaises(ValueError):
                        grub.main()
                    opened.assert_not_called()

    @unittest.skipUnless(shutil.which('mke2fs') and shutil.which('debugfs'), 'needs e2fsprogs')
    def test_real_ext4_image_write_bls_and_fsck(self):
        # Small sparse fixture only. Never open a device or mount a filesystem.
        with tempfile.TemporaryDirectory() as tmp:
            base = pathlib.Path(tmp)
            root = base / 'root'
            (root / 'grub2').mkdir(parents=True)
            (root / 'loader/entries').mkdir(parents=True)
            (root / 'grub2/grub.cfg').write_text('insmod blscfg\nblscfg\n')
            file = root / 'loader/entries/linux.conf'
            file.write_text('title Linux\nlinux /vmlinuz\noptions root=UUID=abc quiet\n')
            file.chmod(0o600)
            image = base / 'boot.img'
            with image.open('wb') as stream:
                stream.truncate(32 * 1024 * 1024)
            subprocess.run(['mke2fs', '-q', '-t', 'ext4', '-F', '-d', str(root), str(image)], check=True)
            fs = grub.Ext4(str(image))
            path = '/loader/entries/linux.conf'
            self.assertEqual(fs.entries(), [path])
            before = fs.read(path)
            after = grub.changed(before.decode(), 'verbose', 'on', {})[0].encode()
            with contextlib.redirect_stdout(io.StringIO()):
                grub.apply(fs, {path: before}, {path: after}, str(base / 'backup'))
            self.assertEqual(fs.read(path), after)
            self.assertIn('Mode:  0600', fs.command('stat ' + path).decode())
            fs.write(path, before)
            fs.check()
            self.assertEqual(fs.read(path), before)


class Detection(unittest.TestCase):
    def candidate(self, device):
        return {'device': device, 'label': 'AURORA_BOOT', 'uuid': 'example',
                'config': '/grub2/grub.cfg', 'bytes': 1024**3}

    def test_probe_filters_system_root_mounted_and_other_linux(self):
        listing = {'AllDisksAndPartitions': [{'Partitions': [
            {'DeviceIdentifier': 'disk0s1', 'Content': 'Apple_APFS'},
            {'DeviceIdentifier': 'disk0s2', 'Content': 'EFI'},
            {'DeviceIdentifier': 'disk0s3', 'Content': 'Linux Filesystem'},
            {'DeviceIdentifier': 'disk0s4', 'Content': 'Linux Filesystem'},
            {'DeviceIdentifier': 'disk0s5', 'Content': 'Linux Filesystem'},
            {'DeviceIdentifier': 'disk0s6', 'Content': 'Linux Filesystem'},
            {'DeviceIdentifier': 'disk0s7', 'Content': 'Linux Filesystem'},
        ]}]}
        probed = []

        class Probe:
            identity = '12345678-1234-1234-1234-123456789abc'

            def __init__(self, device, check=True):
                self.device = device
                self.label = 'AURORA_BOOT' if device.endswith('s5') else 'other'
                self.test_check = check
                probed.append(self)

            def read(self, path):
                if path == '/grub2/grub.cfg' and not self.device.endswith(('s3', 's7')):
                    return b'blscfg\n'
                if self.device.endswith('s6') and path.endswith(self.identity):
                    return b''  # Fedora marker also works without a volume label.
                raise ValueError('missing')

            def write(self, *args):
                raise AssertionError('Discovery must never write')

        def diskutil(command):
            if command[1] == 'list':
                return plistlib.dumps(listing)
            return plistlib.dumps({'WholeDisk': False, 'Mounted': command[-1] == 'disk0s4',
                                   'TotalSize': 1024**3})

        with patch.object(grub, 'run', side_effect=diskutil), patch.object(grub, 'Ext4', Probe):
            found = grub.detect()
        self.assertEqual([x['device'] for x in found], ['disk0s5', 'disk0s6'])
        self.assertEqual([p.device for p in probed], ['/dev/disk0s3', '/dev/disk0s5',
                                                      '/dev/disk0s6', '/dev/disk0s7'])
        self.assertTrue(all(not p.test_check for p in probed))

    def test_unique_selects_without_prompt(self):
        with patch('builtins.open', side_effect=AssertionError('unexpected prompt')), \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(grub.choose([self.candidate('disk0s5')]), 'disk0s5')

    def test_multiple_requires_choice(self):
        candidates = [self.candidate('disk0s5'), self.candidate('disk2s5')]
        with patch('builtins.open', mock_open(read_data='2\n')), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(grub.choose(candidates), 'disk2s5')
        for answer in ['', '0', '3', 'not a number']:
            with patch('builtins.open', mock_open(read_data=answer)), contextlib.redirect_stdout(io.StringIO()):
                with self.assertRaises(ValueError):
                    grub.choose(candidates)
        with patch('builtins.open', side_effect=OSError('no tty')), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(ValueError, 'interactive terminal'):
                grub.choose(candidates)

    def test_no_match(self):
        with self.assertRaisesRegex(ValueError, 'No unmounted Aurora boot'):
            grub.choose([])

    def test_autodetected_device_revalidated_before_write(self):
        def contents(path):
            if path == '/grub2/grub.cfg':
                return CFG.encode()
            raise ValueError('missing')

        original = types.SimpleNamespace(identity='original', read=contents,
                                         check=lambda: None)
        replacement = types.SimpleNamespace(identity='different')
        with patch.object(grub.sys, 'platform', 'darwin'), \
             patch.object(grub.os, 'geteuid', return_value=0), \
             patch.object(grub.sys, 'argv', ['grubcfg.sh', '--apply', 'diagnostic']), \
             patch.object(grub, 'detect', return_value=[self.candidate('disk0s5')]), \
             patch.object(grub, 'unmounted'), \
             patch.object(grub, 'Ext4', side_effect=[original, replacement]), \
             patch.object(grub, 'apply') as writer, contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(ValueError, 'filesystem changed'):
                grub.main()
            writer.assert_not_called()


if __name__ == '__main__':
    unittest.main()
