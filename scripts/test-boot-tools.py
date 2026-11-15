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
from unittest.mock import patch

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


if __name__ == '__main__':
    unittest.main()
