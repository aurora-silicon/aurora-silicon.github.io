#!/bin/sh
# Repairs an Aurora Fedora install, such as one moved from Fedora Asahi Remix
# with upgrade.sh, that keeps booting an older kernel after updates. Run it in
# Linux on that install:
#
#   curl -fsSL https://aurorasilicon.org/asahi-upgrade-repair.sh | sh
#
# To answer yes to both questions, including the reboot:
#   curl -fsSL https://aurorasilicon.org/asahi-upgrade-repair.sh | sh -s -- --yes
#
# The sign: a kernel update printed "15-update-m1n1.install failed with exit
# status 1", and `uname -r` is older than the newest `rpm -q kernel-aurora-core`.
# The Stage 2 updater had refused, so kernel-install stopped before the new
# kernel's initramfs and boot entry. update-m1n1 20261107-6 fixes the cause;
# this script repairs what it left behind:
#
# - boot entries whose kernel is gone (an Asahi kernel removed while the
#   updater refused) move to /var/lib/aurora-repair;
# - the /boot files and entries of kernels whose package is gone (dnf removed
#   it, but the updater stopped kernel-install's cleanup) move there too;
# - kernels from before the DT ABI marker (kernel-aurora 7.3.0-22 and older,
#   Asahi kernels) are declared generation 1, as update-m1n1 20261107-6 does;
# - the system is updated, then each Aurora kernel newer than every kernel
#   with a boot entry is installed again, so the newest one boots next.
#
# Nothing changes until you confirm. The current Stage 2 is kept on the ESP as
# m1n1/boot.bin.pre-repair.

set -eu

ESP=/boot/efi
STAGE2=$ESP/m1n1/boot.bin
BACKUP=$ESP/m1n1/boot.bin.pre-repair
BOOT=/boot
ENTRIES=$BOOT/loader/entries
MODULES=/usr/lib/modules
SAVE=/var/lib/aurora-repair/$(date +%Y%m%d-%H%M%S)

say() { printf '\n==> %s\n' "$*"; }
die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

# Field $2 of BLS entry $1, without leading or trailing blanks.
# shellcheck disable=SC2016 # an awk program
field() { $SUDO awk -v key="$2" '$1 == key { sub(/^[^ \t]+[ \t]+/, ""); sub(/[ \t]+$/, ""); print; exit }' "$1"; }

check_system() {
    [ "$(uname -m)" = aarch64 ] || die "this script is for Apple Silicon Macs running Linux"
    rpm -q kernel-aurora-core >/dev/null 2>&1 || die "no Aurora kernel (kernel-aurora-core) is installed"
    tr '\0' '\n' </proc/device-tree/compatible 2>/dev/null | grep -q '^apple,' ||
        die "this script is for Apple Silicon Macs"
    findmnt -n "$ESP" >/dev/null || die "the EFI system partition isn't mounted at $ESP"
    command -v kernel-install >/dev/null || die "kernel-install is missing"
}

# Boot entries GRUB cannot boot: their kernel exists nowhere it looks.
gone_entries() {
    for entry in $($SUDO find "$ENTRIES" -maxdepth 1 -name '*.conf' 2>/dev/null); do
        image=$(field "$entry" linux)
        version=$(field "$entry" version)
        [ -n "$image" ] || continue
        image=${image#/}
        $SUDO test -e "$BOOT/$image" || $SUDO test -e "/$image" && continue
        [ -n "$version" ] && $SUDO test -e "$MODULES/$version/vmlinuz" && continue
        echo "$entry"
    done
}

# Kernels with a /boot image or a boot entry but no package: no modules
# folder image, no RPM owning the image, and not running. kernel-install
# remove would have deleted them, had the updater not stopped it.
leftover_kernels() {
    {
        for image in $($SUDO find "$BOOT" -maxdepth 1 -name 'vmlinuz-*' ! -name 'vmlinuz-0-rescue-*' 2>/dev/null); do
            echo "${image##*/vmlinuz-}"
        done
        for entry in $($SUDO find "$ENTRIES" -maxdepth 1 -name '*.conf' 2>/dev/null); do
            field "$entry" version
        done
    } | sort -u | while read -r krel; do
        [ -n "$krel" ] && [ "$krel" != "$(uname -r)" ] || continue
        # Only a full release; the file globs below must not match other kernels.
        case $krel in [0-9]*.[0-9]*-?*.?*) ;; *) continue ;; esac
        $SUDO test -e "$MODULES/$krel/vmlinuz" && continue
        rpm -qf "$BOOT/vmlinuz-$krel" >/dev/null 2>&1 && continue
        aurora_kernels | grep -qxF "$krel" && continue
        echo "$krel"
    done
}

# Installed kernels, and Fedora's rescue copies of them, that the updater
# counts as generation 0 because they have no marker.
unmarked_kernels() {
    for image in "$MODULES"/*/vmlinuz; do
        [ -f "$image" ] || continue
        dir=${image%/vmlinuz}
        [ -e "$dir/dtb-abi" ] || echo "${dir##*/}"
    done
    for image in $($SUDO find "$BOOT" -maxdepth 1 -name 'vmlinuz-0-rescue-*' 2>/dev/null); do
        name=${image##*/vmlinuz-}
        [ -e "$MODULES/$name/dtb-abi" ] || echo "$name"
    done
}

aurora_kernels() {
    rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-aurora-core | sort -V
}

# The entries folder may be readable by root only, so glob as root.
# shellcheck disable=SC2016 # expanded by the inner shell
has_entry() { $SUDO sh -c 'grep -qsxF "version $1" "$2"/*.conf' sh "$1" "$ENTRIES"; }

# Aurora kernels newer than every Aurora kernel with a boot entry, oldest first.
stranded_kernels() {
    newest=
    for krel in $(aurora_kernels); do
        if has_entry "$krel"; then newest=$krel; fi
    done
    for krel in $(aurora_kernels); do
        if [ ! -f "$MODULES/$krel/vmlinuz" ] || has_entry "$krel"; then continue; fi
        if [ -n "$newest" ] && [ "$(printf '%s\n%s\n' "$newest" "$krel" | sort -V | tail -n 1)" = "$newest" ]; then
            continue
        fi
        echo "$krel"
    done
}

survey() {
    say "Checking this install"
    RUNNING=$(uname -r)
    NEWEST=$(aurora_kernels | tail -n 1)
    GONE=$(gone_entries)
    LEFTOVER=$(leftover_kernels)
    UNMARKED=$(unmarked_kernels)
    STRANDED=$(stranded_kernels)
    echo "Running kernel:         $RUNNING"
    echo "Newest Aurora kernel:   $NEWEST"
    echo "Entries without kernel: ${GONE:-none}"
    echo "Removed kernels' files: $(echo "${LEFTOVER:-none}" | tr '\n' ' ')"
    echo "Kernels without marker: $(echo "${UNMARKED:-none}" | tr '\n' ' ')"
    echo "Kernels without entry:  $(echo "${STRANDED:-none}" | tr '\n' ' ')"
    if [ -z "$GONE$LEFTOVER$UNMARKED$STRANDED" ] && [ "$RUNNING" = "$NEWEST" ]; then
        echo
        echo "Nothing to repair: the newest Aurora kernel is running."
        exit 0
    fi
}

confirm() {
    cat <<EOF

This moves the entries and the removed kernels' files listed above to
$SAVE, declares the kernels without a marker generation 1
(their device trees work with every later kernel's), updates the system with
dnf, finishes installing the newest Aurora kernel and makes it the default.
Your files and settings stay. Running it again picks up where it stopped.

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
    $SUDO test -e "$BACKUP" || $SUDO cp --preserve=timestamps "$STAGE2" "$BACKUP"
    $SUDO mkdir -p "$SAVE"
}

move_gone_entries() {
    [ -n "$GONE" ] || return 0
    say "Moving boot entries whose kernel is gone"
    $SUDO mkdir -p "$SAVE/entries"
    for entry in $GONE; do
        echo "$entry"
        $SUDO mv "$entry" "$SAVE/entries/"
    done
}

move_leftover_kernels() {
    [ -n "$LEFTOVER" ] || return 0
    say "Moving the files of kernels whose package is gone"
    $SUDO mkdir -p "$SAVE/boot" "$SAVE/entries"
    for krel in $LEFTOVER; do
        echo "$krel"
        for file in $($SUDO find "$BOOT" -maxdepth 1 \( -name "*-$krel" -o -name "*-$krel.*" \
            -o -name ".vmlinuz-$krel.hmac" \) 2>/dev/null); do
            $SUDO mv "$file" "$SAVE/boot/"
        done
        for entry in $($SUDO find "$ENTRIES" -maxdepth 1 -name '*.conf' 2>/dev/null); do
            if [ "$(field "$entry" version)" = "$krel" ]; then
                $SUDO mv "$entry" "$SAVE/entries/"
            fi
        done
    done
}

mark_kernels() {
    [ -n "$UNMARKED" ] || return 0
    say "Declaring kernels from before the DT ABI marker generation 1"
    for krel in $UNMARKED; do
        echo "$krel"
        # A rescue copy has no modules folder; the updater reads its marker there.
        $SUDO test -d "$MODULES/$krel" || {
            $SUDO mkdir "$MODULES/$krel"
            echo "$MODULES/$krel" | $SUDO tee -a "$SAVE/markers" >/dev/null
        }
        printf '1\n' | $SUDO tee "$MODULES/$krel/dtb-abi" >/dev/null
        echo "$MODULES/$krel/dtb-abi" | $SUDO tee -a "$SAVE/markers" >/dev/null
    done
}

update_system() {
    say "Updating the system"
    $SUDO dnf -y --refresh upgrade || die "dnf upgrade failed; fix what it reports and run this again"
}

finish_kernels() {
    for krel in $(stranded_kernels); do
        say "Finishing the install of kernel $krel"
        $SUDO kernel-install add "$krel" "$MODULES/$krel/vmlinuz" ||
            die "kernel-install add $krel failed; see the messages above"
    done
}

check_boot_chain() {
    say "Checking the boot chain"
    kernel=$(aurora_kernels | tail -n 1)
    $SUDO test -s "$BOOT/vmlinuz-$kernel" || die "$BOOT/vmlinuz-$kernel is missing"
    $SUDO test -s "$BOOT/initramfs-$kernel.img" || die "$BOOT/initramfs-$kernel.img is missing"
    has_entry "$kernel" || die "kernel $kernel has no boot entry"
    case $($SUDO grubby --default-kernel) in
    *"/vmlinuz-$kernel") ;;
    *) $SUDO grubby --set-default="/boot/vmlinuz-$kernel" ;;
    esac
    $SUDO update-m1n1 || die "update-m1n1 refused; see its message above"
}

finish() {
    cat <<EOF

Done: kernel $kernel boots next, with a matching Stage 2.

What was moved or added is listed in $SAVE. If the Mac doesn't boot
Linux after this, pick the previous kernel in the GRUB menu, or boot macOS or
recoveryOS, mount this install's EFI system partition and copy
m1n1/boot.bin.pre-repair over m1n1/boot.bin.

EOF
}

reboot_now() {
    if [ "$YES" != 1 ]; then
        printf 'Reboot now to start kernel %s? [Y/n] ' "$kernel"
        { read -r answer </dev/tty; } 2>/dev/null || {
            echo
            answer=n
        }
        case $answer in
        '' | y | Y | yes | YES) ;;
        *)
            echo "Reboot when you can with: systemctl reboot"
            return
            ;;
        esac
    fi
    $SUDO systemctl reboot || echo "Reboot when you can with: systemctl reboot"
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
    survey
    confirm
    # sh reads this script from a pipe; keep child processes off it.
    exec </dev/null
    back_up_stage2
    move_gone_entries
    move_leftover_kernels
    mark_kernels
    update_system
    finish_kernels
    check_boot_chain
    finish
    reboot_now
}

# Last, so a truncated download runs nothing.
main "$@"
