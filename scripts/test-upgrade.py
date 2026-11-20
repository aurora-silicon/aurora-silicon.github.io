#!/usr/bin/env python3
"""Run upgrade.sh's package switch against dnf and rpm doubles."""
import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'public' / 'upgrade.sh'


def switch(installed):
    """The dnf commands switch_packages runs with these packages installed."""
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        (tmp / 'installed').write_text(''.join(name + '\n' for name in installed))
        (tmp / 'dnf.log').touch()
        doubles = {
            'rpm': '[ "$1" = -q ] && grep -qx "$2" "$TEST_ROOT/installed"\n',
            'dnf': 'printf "%s\\n" "$*" >> "$TEST_ROOT/dnf.log"\n',
        }
        for name, body in doubles.items():
            (tmp / name).write_text('#!/bin/sh\n' + body)
            (tmp / name).chmod(0o755)
        # Everything but the final call to main.
        source = SCRIPT.read_text()
        assert source.rstrip().endswith('main "$@"')
        source = source.rstrip()[:-len('main "$@"')]
        env = dict(os.environ, PATH=f'{tmp}:{os.environ["PATH"]}', TEST_ROOT=str(tmp))
        subprocess.run(['sh', '-c', source + '\nSUDO=\nswitch_packages >/dev/null\n'], env=env, check=True)
        return (tmp / 'dnf.log').read_text().splitlines()


class SwitchPackages(unittest.TestCase):
    def test_fex_brings_its_root_filesystem_and_aurora_x86_mesa_in_one_transaction(self):
        commands = switch(['fex-emu'])
        installs = [c for c in commands if ' install ' in f' {c} ']
        self.assertEqual(len(installs), 1)
        words = installs[0].split()
        for name in ('fex-emu-rootfs-fedora', 'mesa-aurora-fex-guest',
                     'mesa-aurora-dri-drivers', 'mesa-aurora-vulkan-drivers'):
            self.assertIn(name, words)
        self.assertIn('--allowerasing', words)

    def test_no_fex_no_guest(self):
        words = ' '.join(switch([])).split()
        self.assertNotIn('fex-emu-rootfs-fedora', words)
        self.assertNotIn('mesa-aurora-fex-guest', words)

    def test_rest_of_the_system_is_upgraded_afterwards(self):
        commands = switch(['fex-emu', 'asahi-repos'])
        self.assertEqual(commands[-2:], ['-y remove asahi-repos', '-y upgrade'])


if __name__ == '__main__':
    unittest.main()
