#!/bin/sh
# Moves a Fedora Asahi Remix or Asahi Arch Linux ARM install to Aurora's
# Stage 2, kernel and packages.
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

# Arch Linux ARM: Aurora's repository as its images list it, and the key that
# signs it.
ALARM_FEED=https://aurorasilicon.org/alarm-aurora
ALARM_REPO=$ALARM_FEED/testing/aarch64
ALARM_KEY=A33623FB30665BEFAA0FFB6DE35EC749219B20F7
ALARM_AURA=/usr/lib/asahi-boot/m1n1.bin
GRUB_EFI=$ESP/EFI/BOOT/BOOTAA64.EFI
GRUB_CFG=/boot/grub/grub.cfg

# Aurora's packages in an Aurora ALARM image, without its desktop.
ALARM_PACKAGES="
    aurora-keyring linux-aurora aurora-userpages aurora-boot aurora-firstboot aurora-sep
    libfprint-aurora aurora-firmware aura uboot-aurora avd-fw libva-v4l2-request-avd
    upower-aurora mesa-aurora vulkan-aurora mesa-aurora-fex-guest aurora-flatpak-gl
    aurora-system-fixes aurora-logos aurora-audio alsa-utils-aurora alsa-ucm-conf-aurora
    aurora-bless aurora-camera-denoise aurora-kbd-light
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
    if [ "${ID:-}" = archarm ]; then
        check_alarm
    else
        check_fedora
    fi

    # Asahi's Fedora and Arch Linux ARM run on M1 and M2. Other SoCs need the
    # Aurora installer.
    tr '\0' '\n' </proc/device-tree/compatible 2>/dev/null |
        grep -qE '^apple,t(8103|8112|600[012]|602[012])$' ||
        die "this script supports M1 and M2 Macs"

    findmnt -n "$ESP" >/dev/null || die "the EFI system partition isn't mounted at $ESP"

    [ "$(free_mb /)" -ge "$MIN_ROOT_MB" ] || die "need ${MIN_ROOT_MB} MB free on /"
    [ "$(free_mb /boot)" -ge "$MIN_BOOT_MB" ] || die "need ${MIN_BOOT_MB} MB free on /boot"

    curl -fsSL -o /dev/null "$REPO_CHECK" || die "cannot reach the Aurora package repository"
}

check_fedora() {
    DISTRO=fedora
    if ! rpm -q aurora-release >/dev/null 2>&1; then
        [ "${ID:-}" = fedora-asahi-remix ] ||
            die "this script is for Fedora Asahi Remix and Asahi Arch Linux ARM (found: ${PRETTY_NAME:-unknown})"
    fi
    FEDORA=${VERSION_ID:-}
    # The releases the Aurora feed publishes.
    case $FEDORA in
    44 | 45) ;;
    *) die "this script supports Fedora Asahi Remix 44 and 45 (found: ${FEDORA:-unknown})" ;;
    esac
    REPO_CHECK=$FEED/$FEDORA/testing/aarch64/repodata/repomd.xml
}

check_alarm() {
    DISTRO=alarm
    [ ! -e /etc/aurora/image-layout ] || die "this is already an Aurora install; update it with: sudo pacman -Syu"
    # Asahi ALARM (asahi-alarm.org) is Arch Linux ARM with Asahi's repository
    # and kernel. After an interrupted run, Aurora's kernel may be there instead.
    grep -q '^\[asahi-alarm\]' /etc/pacman.conf ||
        die "this script is for Asahi Arch Linux ARM (asahi-alarm.org), but /etc/pacman.conf has no [asahi-alarm] repository"
    pacman -Q linux-asahi >/dev/null 2>&1 || pacman -Q linux-aurora >/dev/null 2>&1 ||
        die "this script is for Asahi Arch Linux ARM, but neither linux-asahi nor linux-aurora is installed"
    # These would keep a Stage 2, U-Boot or device trees other than Aurora's.
    if grep -Eq '^[[:space:]]*(M1N1|U_BOOT|DTBS|M1N1_UPDATE_DISABLED)=' /etc/default/update-m1n1 2>/dev/null; then
        die "/etc/default/update-m1n1 sets its own Stage 2, U-Boot or device trees; remove those settings and run this again"
    fi
    [ ! -e /var/lib/pacman/db.lck ] ||
        die "pacman is running; run this again when it has finished (if it isn't, remove /var/lib/pacman/db.lck)"
    REPO_CHECK=$ALARM_REPO/aurora.db
}

confirm() {
    if [ "$DISTRO" = alarm ]; then
        cat <<EOF

This replaces your bootloader's Stage 2, GRUB, kernel, Mesa and audio stack
with Aurora's, using its testing channel, puts Aurora's repository first in
/etc/pacman.conf and updates the rest of the system. Asahi's kernel is
removed. Your files and settings stay.
EOF
    else
        cat <<EOF

This replaces your bootloader's Stage 2, kernel, Mesa, audio stack and system
identity with Aurora's, using its testing channel, and removes the Asahi
repositories. Your files and settings stay.
EOF
    fi
    cat <<EOF

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

back_up_grub() {
    $SUDO test -s "$GRUB_EFI" || die "$GRUB_EFI not found"
    $SUDO test -e "$GRUB_EFI.pre-aurora" || $SUDO cp --preserve=timestamps "$GRUB_EFI" "$GRUB_EFI.pre-aurora"
}

add_alarm_repository() {
    say "Adding the Aurora repository"
    # As Aurora's images do: add the key, then sign it locally by fingerprint,
    # which fails if the download holds another key.
    key=$(mktemp)
    curl -fsSL -o "$key" "$ALARM_FEED/aurora-alarm.asc" || die "cannot download Aurora's signing key"
    $SUDO pacman-key --add "$key" >/dev/null
    rm -f "$key"
    $SUDO pacman-key --lsign-key "$ALARM_KEY" >/dev/null || die "the downloaded key isn't Aurora's ($ALARM_KEY)"

    grep -q '^\[aurora\]' /etc/pacman.conf && return
    conf=$(mktemp)
    # First, as in Aurora's images, so Aurora's builds win over Asahi's and
    # Arch's packages of the same name.
    awk -v server="$ALARM_REPO" '
        !done && /^\[/ && $0 != "[options]" {
            print "[aurora]"
            print "SigLevel = Required DatabaseRequired"
            print "Server = " server
            print ""
            done = 1
        }
        { print }
        END { exit !done }' /etc/pacman.conf >"$conf" || die "/etc/pacman.conf lists no repositories"
    $SUDO test -e /etc/pacman.conf.pre-aurora || $SUDO cp -p /etc/pacman.conf /etc/pacman.conf.pre-aurora
    $SUDO cp "$conf" /etc/pacman.conf
    rm -f "$conf"
}

switch_alarm_packages() {
    say "Installing Aurora's packages"
    extra=
    # Module builds need the headers of the kernel they build for.
    pacman -Q linux-asahi-headers >/dev/null 2>&1 && extra=linux-aurora-headers
    # One transaction with the full upgrade Arch expects, so a failure leaves
    # the system as it was. Aurora's packages conflict with the Asahi ones they
    # replace, and --ask=4 answers pacman's question to remove those with yes.
    # shellcheck disable=SC2086
    $SUDO pacman -Syu --noconfirm --needed --ask=4 $ALARM_PACKAGES $extra

    # pacman applies no unit presets; Aurora's images apply them when they are
    # built, and turn on the FEX Mesa layer.
    # shellcheck disable=SC2086
    units=$(pacman -Qlq $ALARM_PACKAGES |
        sed -nE 's#^/usr/lib/systemd/system/([^/@]+[.](service|socket|timer|path))$#\1#p')
    # shellcheck disable=SC2086
    [ -z "$units" ] || $SUDO systemctl preset --preset-mode=enable-only $units
    $SUDO systemctl enable aurora-fex-mesa.service
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

check_alarm_boot_chain() {
    say "Checking the boot chain"
    kernel=$(pacman -Q linux-aurora | cut -d' ' -f2)
    $SUDO mkinitcpio -p linux-aurora
    $SUDO test -s /boot/vmlinuz-linux-aurora || die "/boot/vmlinuz-linux-aurora is missing"
    $SUDO test -s /boot/initramfs-linux-aurora.img || die "/boot/initramfs-linux-aurora.img is missing"

    # GRUB as Aurora's images install it.
    $SUDO grub-install --target=arm64-efi --efi-directory="$ESP" --removable --no-nvram
    $SUDO grub-mkconfig -o "$GRUB_CFG"
    $SUDO grep -q 'vmlinuz-linux-aurora' "$GRUB_CFG" || die "$GRUB_CFG has no entry for linux-aurora"

    $SUDO update-m1n1 "$STAGE2"
    # boot.bin starts with the Stage 2 binary, followed by device trees and U-Boot.
    size=$(stat -L -c %s "$ALARM_AURA")
    [ "$($SUDO head -c "$size" "$STAGE2" | sha256sum)" = "$(sha256sum <"$ALARM_AURA")" ] ||
        die "$STAGE2 is not Aurora's Stage 2"
}

finish_alarm() {
    cat <<EOF

Done: linux-aurora $kernel with Aurora's Stage 2.

Touch ID sets itself up on the next boot. Enroll with: fprintd-enroll

If the Mac doesn't boot Linux after this, boot macOS or recoveryOS, mount this
install's EFI system partition and copy m1n1/boot.bin.pre-aurora over
m1n1/boot.bin and EFI/BOOT/BOOTAA64.EFI.pre-aurora over EFI/BOOT/BOOTAA64.EFI.

EOF
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
    if [ "$DISTRO" = alarm ]; then
        back_up_grub
        add_alarm_repository
        switch_alarm_packages
        check_alarm_boot_chain
        finish_alarm
    else
        add_repository
        switch_packages
        check_boot_chain
        finish
    fi
    reboot_now
}

# Last, so a truncated download runs nothing.
main "$@"
