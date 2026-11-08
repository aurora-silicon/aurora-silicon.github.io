#!/bin/sh
# Moves a Fedora Asahi Remix install to Aurora's Stage 2, kernel and packages.
#
#   curl -fsSL https://aurorasilicon.org/upgrade.sh | sh
#
# To answer yes to both questions, including the reboot: curl -fsSL https://aurorasilicon.org/upgrade.sh | sh -s -- --yes
#
# Stage 1 stays as it is. Nothing changes until you confirm, and the current
# Stage 2 is kept on the ESP as m1n1/boot.bin.pre-aurora.

set -eu

FEED=https://aurorasilicon.org/fedora-aurora
ESP=/boot/efi
STAGE2=$ESP/m1n1/boot.bin
BACKUP=$ESP/m1n1/boot.bin.pre-aurora
AURA=/usr/lib64/m1n1/m1n1.bin
MIN_ROOT_MB=4096
MIN_BOOT_MB=300

# The set an Aurora Fedora image is built from.
PACKAGES="
    kernel-aurora kernel-aurora-modules-extra aurora-userpages aura uboot-aurora
    aurora-platform aurora-release aurora-logos aurora-remix-scripts aurora-firstboot
    aurora-sep aurora-firmware aurora-audio avd-fw alsa-ucm-conf-aurora speakerguardd
    speakersafetyd-aurora-profiles mesa-aurora-dri-drivers mesa-aurora-vulkan-drivers
    aurora-flatpak-gl
"

say() { printf '\n==> %s\n' "$*"; }
die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

free_mb() { df -Pm "$1" | awk 'NR == 2 { print $4 }'; }

check_system() {
    [ "$(uname -m)" = aarch64 ] || die "this script is for Apple Silicon Macs running Linux"

    # shellcheck disable=SC1091
    . /etc/os-release
    if ! rpm -q aurora-release >/dev/null 2>&1; then
        [ "${ID:-}" = fedora-asahi-remix ] || die "this script is for Fedora Asahi Remix (found: ${PRETTY_NAME:-unknown})"
    fi
    FEDORA=${VERSION_ID:-}
    # The releases the Aurora feed publishes.
    case $FEDORA in
    44 | 45) ;;
    *) die "this script supports Fedora Asahi Remix 44 and 45 (found: ${FEDORA:-unknown})" ;;
    esac

    # Fedora Asahi Remix runs on M1 and M2. Other SoCs need the Aurora installer.
    tr '\0' '\n' </proc/device-tree/compatible 2>/dev/null |
        grep -qE '^apple,t(8103|8112|600[012]|602[012])$' ||
        die "this script supports M1 and M2 Macs"

    findmnt -n "$ESP" >/dev/null || die "the EFI system partition isn't mounted at $ESP"

    [ "$(free_mb /)" -ge "$MIN_ROOT_MB" ] || die "need ${MIN_ROOT_MB} MB free on /"
    [ "$(free_mb /boot)" -ge "$MIN_BOOT_MB" ] || die "need ${MIN_BOOT_MB} MB free on /boot"

    curl -fsSL -o /dev/null "$FEED/$FEDORA/testing/aarch64/repodata/repomd.xml" ||
        die "cannot reach the Aurora package repository"
}

confirm() {
    cat <<EOF

This replaces your bootloader's Stage 2, kernel, Mesa, audio stack and system
identity with Aurora's, using its testing channel, and removes the Asahi
repositories. Your files and settings stay.

Don't use the system until it has finished and rebooted. It replaces the
graphics libraries, so applications started before the reboot may fail to
open or draw wrongly.

EOF
    [ "$YES" = 1 ] && return
    printf 'Continue? [y/N] '
    { read -r answer </dev/tty; } 2>/dev/null || {
        echo
        die "no terminal to confirm on; pass --yes to continue without one"
    }
    case $answer in
    y | Y | yes | YES) ;;
    *) die "nothing was changed" ;;
    esac
}

back_up_stage2() {
    # Only root can read the ESP.
    $SUDO test -s "$STAGE2" || die "$STAGE2 not found"
    # update-m1n1 keeps only the previous boot.bin, and it runs several times here.
    $SUDO test -e "$BACKUP" || $SUDO cp --preserve=timestamps "$STAGE2" "$BACKUP"
}

add_repository() {
    rpm -q aurora-repos >/dev/null 2>&1 && return
    say "Adding the Aurora repository"
    $SUDO dnf -y --repofrompath="aurora,$FEED/$FEDORA/testing/aarch64" \
        --setopt=aurora.gpgcheck=1 --setopt=aurora.gpgkey="$FEED/RPM-GPG-KEY-aurora" \
        install aurora-repos
}

switch_packages() {
    say "Installing Aurora's packages"
    extra=
    # Only systems with a boot splash get Aurora's.
    rpm -q plymouth >/dev/null 2>&1 && extra=plymouth-theme-aurora
    # One transaction, so a failure leaves the system as it was. The vendor
    # switch is needed once: Asahi's protected metapackage blocks it otherwise.
    # shellcheck disable=SC2086
    $SUDO dnf -y --refresh install --allowerasing --allow-vendor-change $PACKAGES $extra

    # Asahi's kernels and bootloader must not replace Aurora's on a later update.
    if rpm -q asahi-repos >/dev/null 2>&1; then
        say "Removing the Asahi repositories"
        $SUDO dnf -y remove asahi-repos
    fi

    say "Updating the rest of the system"
    $SUDO dnf -y upgrade
}

check_boot_chain() {
    say "Checking the boot chain"
    kernel=$(rpm -q kernel-aurora-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -V | tail -n 1)
    # A host-only image would be fitted to the running Asahi kernel, not this one.
    $SUDO dracut -f --no-hostonly --kver "$kernel"
    $SUDO test -s "/boot/vmlinuz-$kernel" || die "/boot/vmlinuz-$kernel is missing"
    $SUDO test -s "/boot/initramfs-$kernel.img" || die "/boot/initramfs-$kernel.img is missing"
    $SUDO test -d "/boot/dtb-$kernel" || die "/boot/dtb-$kernel is missing"

    case $($SUDO grubby --default-kernel) in
    *"/vmlinuz-$kernel") ;;
    *) $SUDO grubby --set-default="/boot/vmlinuz-$kernel" ;;
    esac
    [ "$(readlink /boot/dtb)" = "dtb-$kernel" ] || $SUDO ln -sfn "dtb-$kernel" /boot/dtb

    $SUDO update-m1n1
    # boot.bin starts with the Stage 2 binary, followed by device trees and U-Boot.
    $SUDO cmp -s -n "$(stat -L -c %s "$AURA")" "$AURA" "$STAGE2" || die "$STAGE2 is not Aurora's Stage 2"
}

finish() {
    cat <<EOF

Done: kernel $kernel with Aurora's Stage 2.

Touch ID sets itself up on the next boot. Enroll with: fprintd-enroll

If the Mac doesn't boot Linux after this, boot macOS or recoveryOS, mount this
install's EFI system partition and copy m1n1/boot.bin.pre-aurora over
m1n1/boot.bin. The Asahi kernel is still in the GRUB menu for repairs, but
its graphics don't work with Aurora's Mesa.

EOF
}

reboot_now() {
    if [ "$YES" != 1 ]; then
        printf 'The system must reboot now. Reboot? [Y/n] '
        { read -r answer </dev/tty; } 2>/dev/null || {
            echo
            answer=n
        }
        case $answer in
        '' | y | Y | yes | YES) ;;
        *)
            echo "Reboot as soon as you can with: systemctl reboot"
            return
            ;;
        esac
    fi
    # Aurora's Mesa needs Aurora's kernel, so new applications fail until then.
    $SUDO systemctl reboot || echo "Reboot as soon as you can with: systemctl reboot"
}

main() {
    YES=0
    for arg in "$@"; do
        case $arg in
        -y | --yes) YES=1 ;;
        *) die "unknown option: $arg" ;;
        esac
    done

    SUDO=
    [ "$(id -u)" = 0 ] || SUDO=sudo

    check_system
    confirm
    # sh reads this script from a pipe; keep child processes off it.
    exec </dev/null
    back_up_stage2
    add_repository
    switch_packages
    check_boot_chain
    finish
    reboot_now
}

# Last, so a truncated download runs nothing.
main "$@"
