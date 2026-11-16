---
title: Linux
description: Aurora Silicon’s Linux development and device support.
---

Aurora develops Linux for Apple Silicon. Development covers the kernel, graphics drivers, and the tools needed to run Linux on Apple Silicon Macs.

## Installation and device support

Find your Mac in [device support](/devices/) and read its hardware report before following the [download options](/docs/download/).

Support is recorded per device and software revision. Results for one Mac do not apply automatically to another model with the same chip.

## Boot settings from macOS

Download [grubcfg.sh](/grubcfg.sh) to edit Linux boot arguments and
[verbose.sh](/verbose.sh) to toggle the firmware's `-v` boot argument.
Both are standalone shell scripts with embedded Python 3. They never reboot the Mac.

```sh
curl -fLO https://aurorasilicon.org/grubcfg.sh
curl -fLO https://aurorasilicon.org/verbose.sh
```

Read the downloaded scripts before running them. Python 3 is required; the GRUB
device mode also needs Homebrew's `e2fsprogs`. Install these from an ordinary macOS
session as your normal user:

```sh
brew install python e2fsprogs
```

### Linux / GRUB arguments

Aurora images keep GRUB's main configuration on a separate **ext4 Linux boot
partition**. The FAT EFI partition contains a forwarding file, so editing that
file alone does not change Linux's kernel arguments. macOS does not natively
mount ext4; this helper uses `debugfs` on the unmounted boot partition instead.
It refuses mounted partitions and filesystems that fail a read-only check.
It never repairs a filesystem or changes the partition table.

Find the partition with `diskutil list`, then inspect it. Replace `disk0s5` below
with **your installation's Linux boot partition**, not the EFI, macOS or Linux
root partition. Partition numbers differ between machines. If the filesystem
needs journal recovery or repair, boot Linux to handle that first.

```sh
diskutil list
sudo sh grubcfg.sh --device disk0s5 show

# Preview verbose Linux logs (no writes).
sudo sh grubcfg.sh --device disk0s5 verbose on

# Apply after reviewing the diff. The backup location is printed.
sudo sh grubcfg.sh --device disk0s5 --apply verbose on
```

For a boot stuck before Linux shows any progress, apply the full diagnostic
preset instead:

```sh
# Preview, then apply to the same explicitly selected Linux boot partition.
sudo sh grubcfg.sh --device disk0s5 diagnostic
sudo sh grubcfg.sh --device disk0s5 --apply diagnostic
```

This removes `quiet`, `rhgb` and `splash`, and sets `console=tty0`, `loglevel=7`,
`ignore_loglevel`, `initcall_debug`, `systemd.show_status=1`, `plymouth.enable=0`
and `efi=debug`. Existing non-debug `efi=` flags are preserved; existing
`console=` selections are replaced to request the screen console. It changes
logging, not the installed kernel or device tree. Restore the printed backup
when diagnosis is complete.

Supported actions:

| Action | Effect |
| --- | --- |
| `show` | Print the boot configuration. |
| `edit` | Open a temporary copy in `$EDITOR` (default `vi`), then show the diff. |
| `verbose on` | Remove `quiet`, `rhgb` and `splash`; set `loglevel=7`, `ignore_loglevel`, `systemd.show_status=1`, `plymouth.enable=0`. |
| `verbose off` | Remove those logging/splash overrides and enable `quiet`. |
| `diagnostic` | Apply the full Linux/EFI boot diagnostic preset described above. |
| `nomodeset on` / `nomodeset off` | Add or remove `nomodeset` for display troubleshooting. |
| `add PARAM=VALUE` | Replace that argument's existing value, or add it. |
| `remove PARAM` | Remove the argument by name. |
| `restore BACKUP_DIRECTORY` | Preview or apply the original files from a checksum-checked backup. |

Every modification previews a diff first unless `--apply` is present. An `edit`
preview is not saved for a later invocation: run `--apply edit` to edit and save
in one invocation. With `sudo`, use `sudo env EDITOR=nano sh grubcfg.sh … edit`
if you prefer nano. These editors run with root permissions.

For Fedora's BLS configuration, the helper edits `loader/entries/*.conf`.
It resolves `$kernelopts` from that installation's `grubenv` when needed. For
ordinary GRUB configurations (including ALARM and NixOS), it edits `linux` /
`linuxefi` lines. Presets apply to **all discovered entries**, including recovery
or older kernels. Complex quoted lines require `edit`; the helper does not
execute configuration text. Manual edits are not validated by a GRUB parser.

Writes create a private backup directory in the current directory (override with
`--backup-dir`), verify saved contents, and run a read-only filesystem check.
Keep the printed backup path. For example:

```sh
sudo sh grubcfg.sh --device disk0s5 --apply restore ./grubcfg-backup-20261115-120000
```

`verbose off` selects a quiet preset; `restore` returns to the exact prior contents.
If `/boot` is already accessible through a filesystem driver, `--file
/Volumes/LinuxBoot/grub/grub.cfg` edits that one file instead. An EFI forwarding
file has no kernel lines and cannot use the presets.

These are rescue edits to generated boot files, **not** edits to `/etc/default/grub`
or NixOS configuration. Kernel/package upgrades or `nixos-rebuild` may replace
them. Once Linux boots, make persistent changes through the distribution's normal
configuration tools. For a single boot, GRUB's menu editor is also an option.

### Firmware verbose mode

```sh
sh verbose.sh status
sudo sh verbose.sh on
sudo sh verbose.sh off
```

This changes only the standalone `-v` token in NVRAM `boot-args`, preserving other
arguments and their String/Data encoding. It reads the value back after writing.
It does not change GRUB or enable verbose Linux kernel logs. The firmware setting
can also affect macOS verbose startup.

If firmware policy denies the write, use the **intended Aurora installation's
paired recoveryOS**. Python 3 must also be available there; recoveryOS does not
necessarily include it. The helper does not change security policy, choose a
startup volume, or require disabling SIP. See the
[Asahi boot-process guide](https://asahilinux.org/docs/alt/boot-process-guide/)
for the distinction between firmware verbosity and later boot stages.

## Source code

The [Aurora repositories](https://github.com/aurora-silicon) contain the code and build instructions. The [Linux repository](https://github.com/aurora-silicon/linux) tracks kernel work and hardware discussions.

## Contributing

Read the [contributor guide](/docs/contributing/) and [project policies](/docs/policies/). Include the exact device, software revision, and logs when reporting a hardware result.
