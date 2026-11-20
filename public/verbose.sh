#!/bin/sh
# SPDX-License-Identifier: MIT
# macOS / recoveryOS: change only the -v token in NVRAM boot-args.
set -eu
command -v python3 >/dev/null 2>&1 || { echo 'Install Python 3 (brew install python), then retry.' >&2; exit 1; }
exec python3 - "$@" <<'PY'
import os, pathlib, plistlib, re, subprocess, sys, tempfile


def read_args():
    data = subprocess.check_output(['/usr/sbin/nvram', '-x', '-p'])
    value = plistlib.loads(data).get('boot-args', '')
    decoded = value.decode('utf-8') if isinstance(value, bytes) else value
    if not isinstance(decoded, str) or '\0' in decoded:
        raise ValueError('boot-args is not a UTF-8 string')
    return value


def toggle(value, enabled):
    # Keep every other token, including existing quoting and whitespace.
    value = TOKENS.sub(lambda m: '' if m[0] == '-v' else m[0], value)
    if enabled:
        value += ('' if not value or value[-1].isspace() else ' ') + '-v'
    return value


TOKENS = re.compile(r'''(?:[^\s"'\\]|\\.|"(?:[^"\\]|\\.)*"|'[^']*')+''')


def main():
    action = sys.argv[1:] or ['status']
    if action in (['--help'], ['-h']):
        print('Usage: verbose.sh [status | on | off]\n'
              'Changes only NVRAM boot-args -v; does not change Linux/GRUB arguments.\n'
              'Use sudo for on/off. If denied, use the intended Aurora OS recoveryOS.\n'
              'Do not disable SIP just to run this helper. Never reboots automatically.')
        return
    if len(action) != 1 or action[0] not in ('status', 'on', 'off'):
        raise ValueError('Usage: verbose.sh [status | on | off]')
    if sys.platform != 'darwin':
        raise ValueError('Run this helper on macOS or recoveryOS.')
    raw_before = read_args()
    before = raw_before.decode('utf-8') if isinstance(raw_before, bytes) else raw_before
    print('boot-args:', repr(before))
    if action[0] == 'status':
        print('Verbose:', 'on' if any(m[0] == '-v' for m in TOKENS.finditer(before)) else 'off')
        return
    if os.geteuid() != 0:
        raise ValueError('Run on/off with sudo (or as root in recoveryOS).')
    after = toggle(before, action[0] == 'on')
    if after == before:
        print('Already set; no change.')
        return
    raw_after = after.encode('utf-8') if isinstance(raw_before, bytes) else after
    # XML preserves Data/String type and literal %XX; nvram's text setter can
    # decode percent escapes for Data variables and change unrelated arguments.
    with tempfile.TemporaryDirectory(prefix='aurora-verbose-') as tmp:
        path = pathlib.Path(tmp) / 'boot-args.plist'
        path.write_bytes(plistlib.dumps({'boot-args': raw_after}))
        if read_args() != raw_before:
            raise ValueError('boot-args changed while reading; retry to preserve the new arguments.')
        subprocess.run(['/usr/sbin/nvram', '-x', '-f', str(path)], check=True)
    if read_args() != raw_after:
        raise ValueError('NVRAM read-back differs; inspect verbose.sh status before rebooting.')
    print('Verbose ' + action[0] + '. Other boot arguments preserved. No reboot performed.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        sys.exit('verbose.sh: ' + str(error))
PY
