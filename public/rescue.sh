#!/bin/sh
# Updates the kernel of an Aurora Fedora Remix or Aurora Arch Linux ARM install
# that has no network, from macOS on the same Mac. Run it in macOS:
#
#   curl -fsSL https://aurorasilicon.org/rescue.sh | sudo sh
#
# It downloads the kernel from Aurora's package feed and copies it, with an
# installer, to the install's EFI system partition. Then start Linux and run:
#
#   sudo sh /boot/efi/aurora-kernel/install.sh
#
# Options (after "sudo sh -s --" when piped):
#   --version 7.3.0-20   a kernel other than the newest in the feed
#                        (on Arch Linux ARM, for example 7.3.0.aurora1-21)
#   --fedora 44|45       the install's Fedora release, if it isn't detected
#   --alarm              the install is Aurora Arch Linux ARM
#   --esp disk0s5        the install's EFI system partition, if there are several;
#                        with --fedora or --alarm, also one that doesn't look like it
#   --yes                don't ask before writing to the partition
#
# Nothing is written until you confirm, and then only the aurora-kernel folder
# on that partition.

set -eu

FEED=https://aurorasilicon.org/fedora-aurora
RELEASES=https://github.com/aurora-silicon/fedora-aurora/releases/download
TAGS=https://api.github.com/repos/aurora-silicon/fedora-aurora/git/matching-refs/tags/testing-
FOLDER=aurora-kernel
# The first kernel with the BCM4378 Wi-Fi fix (aurora-silicon/linux#1078).
WIFI_FIX=7.3.0-20
# Kept free for update-m1n1, which writes boot.bin.new and boot.bin.old.
RESERVE_MB=32

# Arch Linux ARM: the feed's testing channel and the releases it serves.
ALARM_FEED=https://aurorasilicon.org/alarm-aurora
ALARM_RELEASES=https://github.com/aurora-silicon/alarm-aurora/releases/download
ALARM_TAGS=https://api.github.com/repos/aurora-silicon/alarm-aurora/git/matching-refs/tags/testing-
# linux-aurora's first package with that fix.
ALARM_WIFI_FIX=7.3.0.aurora1-21

say() { printf '\n==> %s\n' "$*"; }
warn() { printf '\nwarning: %s\n' "$*" >&2; }
die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<EOF
usage: sudo sh rescue.sh [--version V-R] [--fedora 44|45 | --alarm] [--esp DISK] [--yes]

Copies an Aurora kernel to an Aurora Fedora or Arch Linux ARM install's EFI
system partition, to install from Linux with no network:
sudo sh /boot/efi/$FOLDER/install.sh
EOF
}

# Prints the value at a key path in a plist or JSON file.
pget() { plutil -extract "$2" raw -o - "$1" 2>/dev/null; }

# Prints the newest of the versions on standard input.
newest() {
    awk '
    function older(a, b,   x, y, n, m, i) {
        n = split(a, x, /[^0-9A-Za-z]+/)
        m = split(b, y, /[^0-9A-Za-z]+/)
        for (i = 1; i <= n && i <= m; i++) {
            if (x[i] ~ /^[0-9]+$/ && y[i] ~ /^[0-9]+$/) {
                if (x[i] + 0 != y[i] + 0) return x[i] + 0 < y[i] + 0
            } else if (x[i] != y[i]) return x[i] < y[i]
        }
        return n < m
    }
    NF { if (best == "" || older(best, $1)) best = $1 }
    END { print best }'
}

older_than() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | newest)" = "$2" ]; }

ask() {
    printf '%s' "$1"
    { read -r answer </dev/tty; } 2>/dev/null || {
        echo
        die "no terminal to answer on; $2"
    }
}

check_macos() {
    [ "$(uname -s)" = Darwin ] ||
        die "run this in macOS; in Linux with a network, use: sudo dnf upgrade kernel-aurora (Fedora) or sudo pacman -Syu (Arch Linux ARM)"
    [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = 1 ] || die "this script is for Apple Silicon Macs"
    # macOS only lets root mount an EFI system partition.
    [ "$(id -u)" = 0 ] || die "run it as root: curl -fsSL https://aurorasilicon.org/rescue.sh | sudo sh"
    for tool in curl diskutil plutil shasum; do
        command -v "$tool" >/dev/null || die "$tool is missing"
    done
    TMP=$(mktemp -d "${TMPDIR:-/tmp}/aurora-kernel.XXXXXX")
}

# Only removes what this script wrote, and unmounts what it mounted.
cleanup() {
    for dev in $MOUNTED; do
        diskutil unmount "$dev" >/dev/null 2>&1 || warn "couldn't unmount $dev"
    done
    [ -n "$TMP" ] || return 0
    for name in $NAMES disks.plist part.plist efi.list esp.list channels.json tags.json release.sums SHA256SUMS install.sh candidates aurora.db; do
        rm -f "$TMP/$name"
    done
    rmdir "$TMP" 2>/dev/null || :
}

# Prints the EFI partitions on the internal disk, or on the test images.
efi_partitions() {
    if [ -z "$TEST_DISKS" ]; then
        set -- "internal physical"
    else
        # shellcheck disable=SC2086
        set -- $TEST_DISKS
    fi
    for disks in "$@"; do
        # shellcheck disable=SC2086
        diskutil list -plist $disks >"$TMP/disks.plist" || die "diskutil can't list $disks"
        i=0
        while pget "$TMP/disks.plist" "AllDisksAndPartitions.$i.DeviceIdentifier" >/dev/null; do
            j=0
            while part=$(pget "$TMP/disks.plist" "AllDisksAndPartitions.$i.Partitions.$j.DeviceIdentifier"); do
                [ "$(pget "$TMP/disks.plist" "AllDisksAndPartitions.$i.Partitions.$j.Content")" != EFI ] || echo "$part"
                j=$((j + 1))
            done
            i=$((i + 1))
        done
    done
}

part_info() { diskutil info -plist "$1" >"$TMP/part.plist" 2>/dev/null; }

# Prints the Fedora release of the GRUB on a mounted ESP: Fedora's SBAT
# entry names its build, for example grub2,2.12-66.fc44.
esp_fedora() {
    for efi in "$1/EFI/fedora/grubaa64.efi" "$1/EFI/BOOT/BOOTAA64.EFI"; do
        [ -f "$efi" ] || continue
        release=$(LC_ALL=C grep -aoE 'grub2,[^,]*\.fc[0-9]+' "$efi" | sed 's/.*\.fc//' | sort -u)
        case $release in
        [0-9][0-9]) echo "$release" && return ;;
        esac
    done
}

# Arch Linux ARM boots GRUB from the removable path; every GRUB image embeds
# modules, which name grub_mod_init. Fedora, Ubuntu and systemd-boot installs
# have their own folders.
alarm_esp() {
    [ -f "$1/EFI/BOOT/BOOTAA64.EFI" ] && [ ! -d "$1/EFI/fedora" ] && [ ! -d "$1/EFI/ubuntu" ] &&
        [ ! -d "$1/loader" ] && LC_ALL=C grep -aqF grub_mod_init "$1/EFI/BOOT/BOOTAA64.EFI"
}

# Mounts each EFI partition read-only if needed and keeps the ones holding a
# Stage 2 and a Fedora or Arch Linux ARM GRUB, one per line: disk|name|size
# MB|Fedora|mount point|fedora, alarm or other. --fedora and --alarm keep only
# that kind. With --esp, only that partition, whatever it holds.
find_esps() {
    say "Looking for Aurora installs"
    efi_partitions >"$TMP/efi.list"
    if [ -n "$ESP_DEV" ]; then
        awk -v d="$ESP_DEV" '$0 == d' "$TMP/efi.list" >"$TMP/esp.list"
        mv "$TMP/esp.list" "$TMP/efi.list"
    fi
    : >"$TMP/candidates"
    while read -r dev; do
        part_info "$dev" || continue
        [ "$(pget "$TMP/part.plist" FilesystemType)" = msdos ] || continue
        if [ -n "$TEST_DISKS" ]; then
            [ "$(pget "$TMP/part.plist" BusProtocol)" = "Disk Image" ] || die "$dev isn't a disk image"
        fi
        mnt=$(pget "$TMP/part.plist" MountPoint) || mnt=
        if [ -z "$mnt" ]; then
            diskutil mount readOnly -mountOptions nobrowse "$dev" >/dev/null || {
                warn "couldn't mount $dev to look at it"
                continue
            }
            MOUNTED="$MOUNTED $dev"
            part_info "$dev" || continue
            mnt=$(pget "$TMP/part.plist" MountPoint) || continue
        fi
        [ -f "$mnt/m1n1/boot.bin" ] || continue
        kind=other
        if [ -d "$mnt/EFI/fedora" ]; then
            kind=fedora
        elif alarm_esp "$mnt"; then
            kind=alarm
        fi
        if [ -z "$ESP_DEV" ]; then
            [ "$kind" != other ] || continue
            [ -z "$WANT" ] || [ "$kind" = "$WANT" ] || continue
        fi
        printf '%s|%s|%s|%s|%s|%s\n' "$dev" "$(pget "$TMP/part.plist" VolumeName)" \
            "$(($(pget "$TMP/part.plist" TotalSize) / 1000000))" "$(esp_fedora "$mnt")" "$mnt" "$kind" >>"$TMP/candidates"
    done <"$TMP/efi.list"
}

choose_esp() {
    count=$(wc -l <"$TMP/candidates" | tr -d ' ')
    if [ -n "$ESP_DEV" ]; then
        line=$(awk -F'|' -v d="$ESP_DEV" '$1 == d' "$TMP/candidates")
        [ -n "$line" ] || die "$ESP_DEV isn't a FAT EFI system partition with m1n1/boot.bin on this Mac's internal disk"
    elif [ "$count" = 0 ]; then
        case $WANT in
        fedora) die "no Aurora Fedora install found: none of this Mac's EFI system partitions holds EFI/fedora and m1n1/boot.bin" ;;
        alarm) die "no Aurora Arch Linux ARM install found: none of this Mac's EFI system partitions holds m1n1/boot.bin and GRUB at EFI/BOOT/BOOTAA64.EFI" ;;
        *) die "no Aurora install found: none of this Mac's EFI system partitions holds m1n1/boot.bin with EFI/fedora or GRUB at EFI/BOOT/BOOTAA64.EFI" ;;
        esac
    elif [ "$count" = 1 ]; then
        line=$(cat "$TMP/candidates")
    else
        echo
        echo "This Mac has $count Aurora installs, each with its own EFI system partition:"
        echo
        awk -F'|' '{ printf "  %d) %-9s  %-14s  %5s MB  %s\n", NR, $1, $2, $3,
            ($6 == "alarm" ? "Arch Linux ARM" : "Fedora " ($4 == "" ? "unknown" : $4)) }' "$TMP/candidates"
        echo
        [ "$YES" = 0 ] || die "choose one with --esp, for example --esp $(head -n 1 "$TMP/candidates" | cut -d'|' -f1)"
        ask "Which install do you want to update? [1-$count] " "pass --esp to choose one"
        case $answer in
        '' | *[!0-9]*) die "no install chosen" ;;
        esac
        { [ "$answer" -ge 1 ] && [ "$answer" -le "$count" ]; } || die "no install chosen"
        line=$(sed -n "${answer}p" "$TMP/candidates")
    fi
    ESP_DEV=$(echo "$line" | cut -d'|' -f1)
    ESP_NAME=$(echo "$line" | cut -d'|' -f2)
    ESP_MB=$(echo "$line" | cut -d'|' -f3)
    ESP_FEDORA=$(echo "$line" | cut -d'|' -f4)
    ESP_MNT=$(echo "$line" | cut -d'|' -f5)
    KIND=$(echo "$line" | cut -d'|' -f6)
    case $WANT in
    "$KIND") ;;
    fedora)
        warn "$ESP_DEV (\"$ESP_NAME\") has no EFI/fedora, so it doesn't look like a Fedora install.
Using it because --esp and --fedora were given. install.sh only installs on Aurora Fedora $FEDORA."
        KIND=fedora
        ;;
    alarm)
        warn "$ESP_DEV (\"$ESP_NAME\") doesn't look like an Arch Linux ARM install: it has no GRUB at
EFI/BOOT/BOOTAA64.EFI, or has another distribution's folder. Using it because --esp
and --alarm were given. install.sh only installs on Aurora Arch Linux ARM."
        KIND=alarm
        ;;
    *)
        [ "$KIND" != other ] ||
            die "$ESP_DEV has neither EFI/fedora nor GRUB at EFI/BOOT/BOOTAA64.EFI, so it doesn't look like an Aurora install; to use it anyway, also pass --fedora 44, --fedora 45 or --alarm"
        ;;
    esac

    # Leave the other installs' partitions as they were.
    keep=
    for dev in $MOUNTED; do
        if [ "$dev" = "$ESP_DEV" ]; then
            keep="$keep $dev"
        else
            diskutil unmount "$dev" >/dev/null 2>&1 || warn "couldn't unmount $dev"
        fi
    done
    MOUNTED=$keep
}

choose_fedora() {
    if [ -n "$FEDORA" ]; then
        [ -z "$ESP_FEDORA" ] || [ "$ESP_FEDORA" = "$FEDORA" ] ||
            warn "the install's GRUB is from Fedora $ESP_FEDORA, but --fedora $FEDORA was given"
    elif [ -n "$ESP_FEDORA" ]; then
        FEDORA=$ESP_FEDORA
    else
        [ "$YES" = 0 ] || die "can't tell the install's Fedora release; pass --fedora 44 or --fedora 45"
        ask "Which Fedora release does the install run? [44/45] " "pass --fedora"
        FEDORA=$answer
    fi
    case $FEDORA in
    [0-9][0-9]) ;;
    *) die "not a Fedora release: $FEDORA" ;;
    esac
}

# Prints "V-R file" for each kernel in a release's SHA256SUMS, for example
# "7.3.0-20 7.3.0-20.fc44.aurora.aarch64.rpm".
kernels() {
    sed -n "s/^[0-9a-f]\{64\}  kernel-aurora-core-\(\([^-]*\)-\([0-9][^-]*\)\.fc${FEDORA}[^-]*\.aarch64\.rpm\)\$/\2-\3 \1/p" "$1"
}

fetch_sums() { curl -fsSL --retry 3 -o "$TMP/release.sums" "$RELEASES/$1/SHA256SUMS"; }

# Finds the newest release tag for this Fedora that has kernel $1.
search_releases() {
    say "Looking for kernel $1 in Aurora's earlier releases"
    curl -fsSL --retry 3 -o "$TMP/tags.json" "$TAGS" || die "can't list Aurora's releases on GitHub"
    case $FEDORA in
    44) pattern='testing-[0-9]{8}\.[0-9]+' ;;
    *) pattern="testing-f$FEDORA-[0-9]{8}\\.[0-9]+" ;;
    esac
    for tag in $(grep -oE "\"refs/tags/$pattern\"" "$TMP/tags.json" | tr -d '"' | sed 's|refs/tags/||' |
        sed 's/^\(.*-\([0-9]\{8\}\)\.\([0-9]*\)\)$/\2 \3 \1/' | sort -k1,1nr -k2,2nr | cut -d' ' -f3 | head -n 40); do
        fetch_sums "$tag" || continue
        if kernels "$TMP/release.sums" | grep -q "^$1 "; then
            TAG=$tag
            return
        fi
    done
    die "kernel $1 for Fedora $FEDORA isn't in the feed or in Aurora's last 40 releases"
}

choose_kernel() {
    say "Reading Aurora's package feed for Fedora $FEDORA"
    curl -fsSL --retry 3 -o "$TMP/channels.json" "$FEED/channels.json" || die "can't reach $FEED"
    DEPLOYED=$(pget "$TMP/channels.json" "channels.$FEDORA/testing.tag") ||
        DEPLOYED=$(pget "$TMP/channels.json" "channels.testing.tag") ||
        die "the feed doesn't name its current release"
    TAG=$DEPLOYED
    fetch_sums "$TAG" || die "can't download the checksums of release $TAG"

    if [ -z "$VERSION" ]; then
        VERSION=$(kernels "$TMP/release.sums" | cut -d' ' -f1 | newest)
        [ -n "$VERSION" ] || die "the feed has no Aurora kernel for Fedora $FEDORA"
    elif ! kernels "$TMP/release.sums" | grep -q "^$VERSION "; then
        search_releases "$VERSION"
        warn "kernel $VERSION is from release $TAG, not $DEPLOYED, the one the feed serves now"
    fi
    rest=$(kernels "$TMP/release.sums" | awk -v v="$VERSION" '$1 == v { print $2; exit }')
    KREL=${rest%.rpm}

    # The kernel, its modules, the userpages launcher built with it, and the
    # release's Stage 2, which install.sh only installs when the kernel needs it.
    NAMES="kernel-aurora-$rest kernel-aurora-core-$rest kernel-aurora-modules-extra-$rest aurora-userpages-$rest"
    AURA=$(sed -n "s/^[0-9a-f]\{64\}  \(aura-[0-9][^ ]*\.fc$FEDORA\.aarch64\.rpm\)\$/\1/p" "$TMP/release.sums" | tail -n 1)
    [ -z "$AURA" ] || NAMES="$NAMES $AURA"

    : >"$TMP/SHA256SUMS"
    for name in $NAMES; do
        awk -v n="$name" '$2 == n' "$TMP/release.sums" | grep . >>"$TMP/SHA256SUMS" ||
            die "release $TAG has no $name"
    done
    BASE=$RELEASES/$TAG
    DISTRO_NAME="Fedora $FEDORA"
}

# Prints the desc entry of package $2 in pacman database $1. Entries are
# named NAME-PKGVER-PKGREL, so linux-aurora doesn't match linux-aurora-headers.
db_desc() {
    entry=$(tar -tf "$1" | grep -E "^$2-[^-/]+-[^-/]+/desc\$" | head -n 1)
    [ -n "$entry" ] && tar -xOf "$1" "$entry"
}

# Prints field %$1% of the desc entry on standard input.
desc_field() { awk -v k="%$1%" '$0 == k { getline; print; exit }'; }

fetch_alarm() { curl -fsSL --retry 3 -o "$TMP/$2" "$1"; }

# Finds the newest release with linux-aurora $1.
search_alarm_releases() {
    say "Looking for kernel $1 in Aurora's earlier releases"
    curl -fsSL --retry 3 -o "$TMP/tags.json" "$ALARM_TAGS" || die "can't list Aurora's releases on GitHub"
    for tag in $(grep -oE '"refs/tags/testing-[0-9]{8}\.[0-9]+"' "$TMP/tags.json" | tr -d '"' | sed 's|refs/tags/||' |
        sed 's/^\(.*-\([0-9]\{8\}\)\.\([0-9]*\)\)$/\2 \3 \1/' | sort -k1,1nr -k2,2nr | cut -d' ' -f3 | head -n 40); do
        fetch_alarm "$ALARM_RELEASES/$tag/SHA256SUMS" release.sums || continue
        if awk -v p="linux-aurora-$1-aarch64.pkg.tar." 'index($2, p) == 1 && $2 !~ /\.sig$/ { found = 1 } END { exit !found }' \
            "$TMP/release.sums"; then
            TAG=$tag
            return
        fi
    done
    die "kernel $1 isn't in the feed or in Aurora's last 40 releases"
}

# The kernel the testing channel serves, from its pacman database, checked
# against the checksums of the release the channel names.
choose_alarm_kernel() {
    say "Reading Aurora's package feed for Arch Linux ARM"
    fetch_alarm "$ALARM_FEED/channels.json" channels.json || die "can't reach $ALARM_FEED"
    DEPLOYED=$(pget "$TMP/channels.json" channels.testing.tag) || die "the feed doesn't name its current release"
    TAG=$DEPLOYED
    BASE=$ALARM_FEED/testing/aarch64
    fetch_alarm "$BASE/aurora.db" aurora.db || die "can't download the feed's package database"
    served=$(db_desc "$TMP/aurora.db" linux-aurora | desc_field VERSION)
    [ -n "$served" ] || die "the feed has no linux-aurora"
    if [ -z "$VERSION" ]; then
        VERSION=$served
    elif [ "$VERSION" != "$served" ]; then
        search_alarm_releases "$VERSION"
        warn "kernel $VERSION is from release $TAG, not $DEPLOYED, the one the feed serves now"
        BASE=$ALARM_RELEASES/$TAG
        fetch_alarm "$BASE/aurora.db" aurora.db || die "can't download the package database of release $TAG"
    fi
    fetch_alarm "$ALARM_RELEASES/$TAG/SHA256SUMS" release.sums ||
        warn "release $TAG has no checksums; checking the downloads against the package database"
    KREL=$VERSION
    DISTRO_NAME="Arch Linux ARM"

    # The kernel, the userpages launcher built with it, and the release's
    # Stage 2, which install.sh only installs when the kernel needs it.
    NAMES='' ALARM_FILES=''
    : >"$TMP/SHA256SUMS"
    for pkg in linux-aurora aurora-userpages aura; do
        desc=$(db_desc "$TMP/aurora.db" "$pkg") || die "release $TAG has no $pkg"
        file=$(printf '%s\n' "$desc" | desc_field FILENAME)
        sum=$(printf '%s\n' "$desc" | desc_field SHA256SUM)
        case $file in
        "$pkg"-[0-9]*.pkg.tar.*) ;;
        *) die "release $TAG has no $pkg package" ;;
        esac
        if [ -f "$TMP/release.sums" ]; then
            [ "$(awk -v n="$file" '$2 == n { print $1 }' "$TMP/release.sums")" = "$sum" ] ||
                die "the package database and release $TAG disagree about $file; run this again in a few minutes"
            awk -v n="$file.sig" '$2 == n' "$TMP/release.sums" | grep . >>"$TMP/SHA256SUMS" ||
                die "release $TAG has no $file.sig"
        fi
        printf '%s  %s\n' "$sum" "$file" >>"$TMP/SHA256SUMS"
        NAMES="$NAMES $file $file.sig"
        ALARM_FILES="$ALARM_FILES $file"
    done
    [ "$(db_desc "$TMP/aurora.db" aurora-userpages | desc_field VERSION)" = "$VERSION" ] ||
        die "release $TAG has no aurora-userpages $VERSION"
}

download() {
    say "Downloading kernel $KREL from release $TAG"
    for name in $NAMES; do
        curl -fL --retry 3 --progress-bar -o "$TMP/$name" "$BASE/$name" || die "couldn't download $name"
    done
    (cd "$TMP" && shasum -a 256 -c --status SHA256SUMS) || die "a download doesn't match its checksum; run this again"
    # Signatures without a published checksum are listed too, so install.sh
    # notices damage and a rerun can remove them; pacman checks them.
    for name in $NAMES; do
        awk -v n="$name" '$2 == n { found = 1 } END { exit !found }' "$TMP/SHA256SUMS" ||
            (cd "$TMP" && shasum -a 256 "$name") >>"$TMP/SHA256SUMS"
    done
    bytes=0
    for name in $NAMES; do
        bytes=$((bytes + $(stat -f %z "$TMP/$name")))
    done
    SIZE_KB=$((bytes / 1024))
}

check_space() {
    df_kb=$(df -k "$ESP_MNT" | awk 'NR == 2 { print $4 }')
    old_kb=0
    [ ! -d "$ESP_MNT/$FOLDER" ] || old_kb=$(du -sk "$ESP_MNT/$FOLDER" | awk '{ print $1 }')
    boot_kb=$(du -k "$ESP_MNT/m1n1/boot.bin" | awk '{ print $1 }')
    need_kb=$((SIZE_KB + 2 * boot_kb + RESERVE_MB * 1024))
    [ $((df_kb + old_kb)) -ge "$need_kb" ] ||
        die "the EFI system partition has $(((df_kb + old_kb) / 1024)) MB free; the kernel and room for update-m1n1 need $((need_kb / 1024)) MB"
}

confirm() {
    fix=$WIFI_FIX
    [ "$KIND" != alarm ] || fix=$ALARM_WIFI_FIX
    if older_than "$VERSION" "$fix"; then
        warn "kernel $VERSION is older than $fix and doesn't have the Wi-Fi fix for Macs with a
BCM4378 (M1 MacBook Air, 13-inch M1 and M2 MacBook Pro, and probably M1 Mac mini).
On those Macs, Wi-Fi in Linux stays broken with this kernel."
    fi
    cat <<EOF

This copies Aurora kernel $KREL ($((SIZE_KB / 1024)) MB, release $TAG)
for $DISTRO_NAME to the folder $FOLDER on the EFI system partition
$ESP_DEV ("$ESP_NAME", $ESP_MB MB). Nothing else on the partition changes.

EOF
    [ "$YES" = 1 ] && return
    ask 'Continue? [y/N] ' "pass --yes to continue without one"
    case $answer in
    y | Y | yes | YES) ;;
    *) die "nothing was changed" ;;
    esac
}

# The partition was mounted read-only to look at it.
mount_writable() {
    part_info "$ESP_DEV" || die "diskutil can't read $ESP_DEV"
    [ "$(pget "$TMP/part.plist" WritableVolume)" = true ] && return
    case " $MOUNTED " in
    *" $ESP_DEV "*) ;;
    *) die "$ESP_DEV is mounted read-only at $ESP_MNT; unmount it and run this again" ;;
    esac
    diskutil unmount "$ESP_DEV" >/dev/null || die "couldn't unmount $ESP_DEV"
    MOUNTED=
    diskutil mount -mountOptions nobrowse "$ESP_DEV" >/dev/null || die "couldn't mount $ESP_DEV"
    MOUNTED=$ESP_DEV
    part_info "$ESP_DEV" || die "couldn't mount $ESP_DEV"
    ESP_MNT=$(pget "$TMP/part.plist" MountPoint)
}

# Removes an earlier copy, file by file, so nothing else can be deleted.
remove_old_copy() {
    dir=$ESP_MNT/$FOLDER
    [ -d "$dir" ] || return 0
    old=
    [ ! -f "$dir/SHA256SUMS" ] ||
        old=$(awk '$2 ~ /^[A-Za-z0-9._+~-]+\.(rpm|pkg\.tar\.(xz|zst)(\.sig)?)$/ { print $2 }' "$dir/SHA256SUMS")
    for name in $old SHA256SUMS install.sh .DS_Store; do
        rm -f "$dir/$name" "$dir/._$name"
    done
    rmdir "$dir" 2>/dev/null || die "$dir holds files this script didn't write; move them away and run this again"
}

write_installer() {
    {
        cat <<'EOF'
#!/bin/sh
# Installs the Aurora kernel that rescue.sh copied to this folder,
# without a network, then removes the folder. Run it in Linux:
#
#   sudo sh /boot/efi/aurora-kernel/install.sh
#
# --yes answers yes to both questions, including the reboot.

set -eu

EOF
        echo "# Written by rescue.sh."
        echo "FEDORA=$FEDORA"
        echo "CORE_RPM=kernel-aurora-core-$rest"
        echo "KERNEL_RPMS=\"kernel-aurora-$rest kernel-aurora-core-$rest kernel-aurora-modules-extra-$rest\""
        echo "USERPAGES_RPM=aurora-userpages-$rest"
        echo "AURA_RPM=$AURA"
        cat <<'EOF'

ESP=/boot/efi
STAGE2=$ESP/m1n1/boot.bin
AURA=/usr/lib64/m1n1/m1n1.bin
# Aurora's package signing key.
KEY=d6c974933c41aace00ae3c4591b639b8c6a77ac1

say() { printf '\n==> %s\n' "$*"; }
die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

vercmp() { rpm --eval "%{lua: print(rpm.vercmp('$1', '$2'))}"; }

check_system() {
    [ "$(id -u)" = 0 ] || die "run it as root: sudo sh $0"
    [ "$(uname -m)" = aarch64 ] || die "run it in the Aurora Fedora install"
    { command -v rpm >/dev/null && rpm -q --quiet kernel-aurora-core; } ||
        die "this isn't an Aurora Fedora install: kernel-aurora-core isn't installed"
    # shellcheck disable=SC1091
    release=$(. /etc/os-release && echo "${VERSION_ID:-}")
    [ "$release" = "$FEDORA" ] ||
        die "this kernel is for Fedora $FEDORA, but this install runs Fedora ${release:-unknown}; in macOS, run rescue.sh again with --fedora $release"
    findmnt -n "$ESP" >/dev/null || die "the EFI system partition isn't mounted at $ESP"
}

verify() {
    say "Checking the packages"
    cd "$DIR"
    sha256sum -c --quiet SHA256SUMS || die "files in $DIR are damaged; in macOS, run rescue.sh again"
    for rpm in $KERNEL_RPMS $USERPAGES_RPM $AURA_RPM; do
        out=$(rpm -Kv "$rpm" 2>&1) || {
            printf '%s\n' "$out" >&2
            case $out in
            *NOKEY*) die "Aurora's signing key isn't in the rpm database; import it with: rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-aurora" ;;
            *) die "$rpm failed its signature check" ;;
            esac
        }
        printf '%s\n' "$out" | grep -qiE "(fingerprint: $KEY|key ID c6a77ac1): OK" ||
            die "$rpm isn't signed with Aurora's key"
    done
    # GitHub renames ~ in file names, so the release comes from the package.
    KREL=$(rpm -qp --qf '%{VERSION}-%{RELEASE}.%{ARCH}' "$CORE_RPM")
}

# Succeeds if package file $1 isn't installed, or is newer than what is.
newer() {
    name=$(rpm -qp --qf '%{NAME}' "$1")
    rpm -q --quiet "$name" || return 0
    [ "$(vercmp "$(rpm -q --qf '%{EPOCHNUM}:%{VERSION}-%{RELEASE}' "$name")" \
        "$(rpm -qp --qf '%{EPOCHNUM}:%{VERSION}-%{RELEASE}' "$1")")" -lt 0 ]
}

# Succeeds if the kernel needs a newer Stage 2 than the installed one.
aura_needed() {
    [ -n "$AURA_RPM" ] || return 1
    need=$(rpm -qp --requires "$CORE_RPM" | awk '$1 == "aura" && $2 == ">=" { print $3; exit }')
    [ -n "$need" ] || return 1
    rpm -q --quiet aura || return 0
    [ "$(vercmp "$(rpm -q --qf '%{VERSION}-%{RELEASE}' aura)" "$need")" -lt 0 ]
}

plan() {
    INSTALL=
    for rpm in $KERNEL_RPMS; do
        INSTALL="$INSTALL $DIR/$rpm"
    done
    # The launcher uses the kernel's private prctl numbers; keep a newer one.
    if newer "$USERPAGES_RPM"; then
        INSTALL="$INSTALL $DIR/$USERPAGES_RPM"
    fi
    STAGE2_NOTE=
    if aura_needed; then
        INSTALL="$INSTALL $DIR/$AURA_RPM"
        STAGE2_NOTE="
It also updates Stage 2 to aura $(rpm -qp --qf '%{VERSION}' "$AURA_RPM"), which this kernel needs."
    fi
}

confirm() {
    cat <<END

This installs Aurora kernel $KREL from $DIR
without a network and makes it GRUB's default.$STAGE2_NOTE
The running kernel, $(uname -r), stays in the GRUB menu.

END
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

install_kernel() {
    say "Installing kernel $KREL"
    # Every repository is off: aurora.repo stops dnf when its feed can't be
    # reached, and the dependencies are already installed. dnf doesn't check
    # local packages' signatures unless asked.
    # shellcheck disable=SC2086
    dnf -y --disablerepo='*' --setopt=localpkg_gpgcheck=1 install $INSTALL && return
    # A failed scriptlet fails the transaction but leaves the kernel installed.
    rpm -q --quiet "kernel-aurora-core-$KREL" || die "dnf couldn't install kernel $KREL"
    echo "dnf reported an error after installing the kernel; checking the boot chain."
}

check_boot_chain() {
    say "Checking the boot chain"
    if [ ! -s "/boot/vmlinuz-$KREL" ] || [ ! -s "/boot/initramfs-$KREL.img" ]; then
        kernel-install add "$KREL" "/usr/lib/modules/$KREL/vmlinuz"
    fi
    [ -s "/boot/vmlinuz-$KREL" ] || die "/boot/vmlinuz-$KREL is missing"
    [ -s "/boot/initramfs-$KREL.img" ] || die "/boot/initramfs-$KREL.img is missing"
    [ -d "/boot/dtb-$KREL" ] || die "/boot/dtb-$KREL is missing"

    grubby --set-default="/boot/vmlinuz-$KREL"
    [ "$(grubby --default-kernel)" = "/boot/vmlinuz-$KREL" ] || die "GRUB's default isn't kernel $KREL"
    [ "$(readlink /boot/dtb)" = "dtb-$KREL" ] || ln -sfn "dtb-$KREL" /boot/dtb

    # boot.bin is Stage 2, the device trees from /boot/dtb, then U-Boot.
    update-m1n1
    [ "$(stat -c %Y "$STAGE2")" -ge $((START - 2)) ] || die "update-m1n1 didn't rewrite $STAGE2"
    size=$(stat -L -c %s "$AURA")
    cmp -s -n "$size" "$AURA" "$STAGE2" || die "$STAGE2 doesn't start with Aurora's Stage 2"
    for dtb in "/boot/dtb-$KREL"/apple/t6*.dtb "/boot/dtb-$KREL"/apple/t81*.dtb; do
        [ -f "$dtb" ] && break
    done
    [ -f "$dtb" ] || die "/boot/dtb-$KREL has no Apple device trees"
    cmp -s -i "$size:0" -n "$(stat -c %s "$dtb")" "$STAGE2" "$dtb" ||
        die "$STAGE2 doesn't carry kernel $KREL's device trees"
}

# Removes the files rescue.sh wrote, by name.
remove_folder() {
    cd /
    # macOS can leave ._ and .DS_Store files on FAT.
    for name in $KERNEL_RPMS $USERPAGES_RPM $AURA_RPM SHA256SUMS install.sh .DS_Store; do
        rm -f "$DIR/$name" "$DIR/._$name"
    done
    if rmdir "$DIR" 2>/dev/null; then
        rm -f "$(dirname "$DIR")/._$(basename "$DIR")"
    else
        echo "$DIR holds other files, so it stays."
    fi
}

reboot_now() {
    echo
    echo "Done: kernel $KREL is installed and is GRUB's default."
    if [ "$YES" != 1 ]; then
        printf 'Reboot now to start it? [Y/n] '
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
    systemctl reboot || echo "Reboot when you can with: systemctl reboot"
}

main() {
    YES=0
    for arg in "$@"; do
        case $arg in
        -y | --yes) YES=1 ;;
        *) die "unknown option: $arg" ;;
        esac
    done
    DIR=$(cd "$(dirname "$0")" && pwd)
    START=$(date +%s)

    check_system
    verify
    plan
    confirm
    install_kernel
    check_boot_chain
    remove_folder
    reboot_now
}

# Last, so a truncated copy runs nothing.
main "$@"
EOF
    } >"$TMP/install.sh"
}

write_alarm_installer() {
    # shellcheck disable=SC2086
    set -- $ALARM_FILES
    {
        cat <<'EOF'
#!/bin/sh
# Installs the Aurora kernel that rescue.sh copied to this folder,
# without a network, then removes the folder. Run it in Linux:
#
#   sudo sh /boot/efi/aurora-kernel/install.sh
#
# --yes answers yes to both questions, including the reboot.

set -eu

EOF
        echo "# Written by rescue.sh."
        echo "KERNEL_PKG=$1"
        echo "USERPAGES_PKG=$2"
        echo "AURA_PKG=$3"
        cat <<'EOF'

ESP=/boot/efi
STAGE2=$ESP/m1n1/boot.bin
# Aurora's package signing key, and the keyring pacman checks it with.
KEY=A33623FB30665BEFAA0FFB6DE35EC749219B20F7
KEYRING=/etc/pacman.d/gnupg
M1N1_CONFIG=/etc/default/update-m1n1

say() { printf '\n==> %s\n' "$*"; }
die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

sha() { sha256sum | cut -d' ' -f1; }

check_system() {
    [ "$(id -u)" = 0 ] || die "run it as root: sudo sh $0"
    [ "$(uname -m)" = aarch64 ] || die "run it in the Aurora Arch Linux ARM install"
    { command -v pacman >/dev/null && pacman -Q linux-aurora >/dev/null 2>&1; } ||
        die "this isn't an Aurora Arch Linux ARM install: linux-aurora isn't installed"
    [ ! -e /var/lib/pacman/db.lck ] ||
        die "pacman is running; run this again when it has finished (if it isn't, remove /var/lib/pacman/db.lck)"
    findmnt -n "$ESP" >/dev/null || die "the EFI system partition isn't mounted at $ESP"
}

verify() {
    say "Checking the packages"
    cd "$DIR"
    sha256sum -c --quiet SHA256SUMS || die "files in $DIR are damaged; in macOS, run rescue.sh again"
    for pkg in $KERNEL_PKG $USERPAGES_PKG $AURA_PKG; do
        # pacman-key --verify's test, and the signer must be Aurora's key.
        out=$(gpg --homedir "$KEYRING" --no-permission-warning --batch --status-fd 1 \
            --verify "$pkg.sig" "$pkg" 2>/dev/null) || {
            case $out in
            *NO_PUBKEY*) die "Aurora's signing key isn't in pacman's keyring; add it with: pacman-key --populate aurora" ;;
            *) die "$pkg failed its signature check" ;;
            esac
        }
        printf '%s\n' "$out" | grep -q "^\[GNUPG:\] VALIDSIG .*$KEY" || die "$pkg isn't signed with Aurora's key"
        printf '%s\n' "$out" | grep -qE '^\[GNUPG:\] TRUST_(FULLY|ULTIMATE)' ||
            die "pacman's keyring doesn't trust Aurora's key; trust it with: pacman-key --populate aurora"
    done
    # Versions come from the packages, not the file names.
    NEW=$(pacman -Qp "$KERNEL_PKG" | cut -d' ' -f2)
}

# Succeeds if package file $1 isn't installed, or is newer than what is.
newer() {
    # shellcheck disable=SC2046
    set -- $(pacman -Qp "$1")
    installed=$(pacman -Q "$1" 2>/dev/null | cut -d' ' -f2)
    [ -z "$installed" ] || [ "$(vercmp "$installed" "$2")" -lt 0 ]
}

# Succeeds if the kernel needs a newer Stage 2 than the installed one.
aura_needed() {
    need=$(LC_ALL=C pacman -Qip "$KERNEL_PKG" | sed -n 's/^Depends On *: //p' | tr ' ' '\n' |
        sed -n 's/^aura>=//p' | head -n 1)
    [ -n "$need" ] || return 1
    have=$(pacman -Q aura 2>/dev/null | cut -d' ' -f2)
    [ -z "$have" ] || [ "$(vercmp "$have" "$need")" -lt 0 ]
}

plan() {
    CURRENT=$(pacman -Q linux-aurora | cut -d' ' -f2)
    INSTALL=$DIR/$KERNEL_PKG
    # The launcher uses the kernel's private prctl numbers; keep a newer one.
    if newer "$USERPAGES_PKG"; then
        INSTALL="$INSTALL $DIR/$USERPAGES_PKG"
    fi
    STAGE2_NOTE=
    if aura_needed; then
        INSTALL="$INSTALL $DIR/$AURA_PKG"
        STAGE2_NOTE="
It also updates Stage 2 to aura $(pacman -Qp "$AURA_PKG" | cut -d' ' -f2), which this kernel needs."
    fi
}

confirm() {
    if [ "$CURRENT" = "$NEW" ]; then
        echo
        echo "Aurora kernel $NEW is already installed. This checks that the initramfs,"
        echo "GRUB and m1n1/boot.bin are up to date."
    else
        older=
        [ "$(vercmp "$CURRENT" "$NEW")" -lt 0 ] || older="older "
        cat <<END

This replaces kernel $CURRENT with the ${older}Aurora kernel $NEW
from $DIR, without a network.$STAGE2_NOTE
Reboot soon after: the running kernel's modules are replaced.
END
    fi
    echo
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

install_kernel() {
    say "Installing kernel $NEW"
    # Local files only: their dependencies are installed, so pacman needs no
    # repository.
    # shellcheck disable=SC2086
    pacman -U --noconfirm --needed $INSTALL && return
    # A failed hook can fail the transaction after the package is in.
    [ "$(pacman -Q linux-aurora | cut -d' ' -f2)" = "$NEW" ] || die "pacman couldn't install kernel $NEW"
    echo "pacman reported an error after installing the kernel; checking the boot chain."
}

# Prints a setting from update-m1n1's configuration, read as update-m1n1 does.
m1n1_setting() {
    [ -f "$M1N1_CONFIG" ] || return 0
    (
        set +eu
        # shellcheck disable=SC1090
        . "$M1N1_CONFIG" >/dev/null 2>&1
        eval "printf '%s' \"\${$1-}\""
    )
}

# Fails unless the first device tree after Stage 2 ($1 bytes) is one of the
# new kernel's.
check_dtb() {
    magic=$(tail -c +$(($1 + 1)) "$STAGE2" | head -c 8 | od -An -tx1 | tr -d ' \n')
    case $magic in
    d00dfeed????????) ;;
    *) die "$STAGE2 has no device tree after Stage 2" ;;
    esac
    dt=$(tail -c +$(($1 + 1)) "$STAGE2" | head -c $((0x${magic#d00dfeed})) | sha)
    for dtb in "/usr/lib/modules/$KVER/dtbs/"*.dtb; do
        [ "$(sha <"$dtb")" != "$dt" ] || return 0
    done
    die "$STAGE2 doesn't carry kernel $NEW's device trees"
}

check_boot_chain() {
    say "Checking the boot chain"
    KVER=$(pacman -Qlq linux-aurora | sed -n 's|^/usr/lib/modules/\([^/]*\)/vmlinuz$|\1|p')
    [ -n "$KVER" ] || die "linux-aurora has no kernel image"
    kernel=/usr/lib/modules/$KVER/vmlinuz

    # mkinitcpio's pacman hook copies the kernel to /boot and builds the initramfs.
    preset=/etc/mkinitcpio.d/linux-aurora.preset
    image=$(sed -n 's/^ALL_kver="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' "$preset" 2>/dev/null)
    initrd=$(sed -n 's/^default_image="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' "$preset" 2>/dev/null)
    image=${image:-/boot/vmlinuz-linux-aurora}
    initrd=${initrd:-/boot/initramfs-linux-aurora.img}
    if [ ! -s "$image" ] || [ "$(sha <"$image")" != "$(sha <"$kernel")" ] ||
        [ ! -s "$initrd" ] || [ "$(stat -c %Y "$initrd")" -lt "$START" ]; then
        install -m 644 "$kernel" "$image"
        mkinitcpio -p linux-aurora
    fi
    [ "$(sha <"$image")" = "$(sha <"$kernel")" ] || die "$image isn't kernel $NEW"
    if [ ! -s "$initrd" ] || [ "$(stat -c %Y "$initrd")" -lt "$START" ]; then
        die "$initrd wasn't rebuilt"
    fi

    # aurora-userpages' pacman hook runs grub-mkconfig before mkinitcpio's
    # has put the kernel back in /boot, so the result can lack it.
    cfg=/boot/grub/grub.cfg
    if [ -f "$cfg" ] && command -v grub-mkconfig >/dev/null; then
        grub-mkconfig -o "$cfg"
        grep -qF "${image##*/}" "$cfg" || die "$cfg has no entry for ${image##*/}"
    else
        echo "There's no $cfg, so GRUB's configuration stays as it is."
    fi

    # asahi-scripts' pacman hook runs update-m1n1: Stage 2, the device trees
    # of the newest kernel, then U-Boot.
    if [ -n "$(m1n1_setting M1N1_UPDATE_DISABLED)" ]; then
        echo "update-m1n1 is turned off in $M1N1_CONFIG, so $STAGE2 stays as it is."
        return
    fi
    [ "$(stat -c %Y "$STAGE2")" -ge $((START - 2)) ] || update-m1n1
    [ "$(stat -c %Y "$STAGE2")" -ge $((START - 2)) ] || die "update-m1n1 didn't rewrite $STAGE2"
    pinned=$(m1n1_setting M1N1)
    stage=${pinned:-/usr/lib/asahi-boot/m1n1.bin}
    size=$(stat -L -c %s "$stage")
    [ "$(head -c "$size" "$STAGE2" | sha)" = "$(sha <"$stage")" ] || die "$STAGE2 doesn't start with $stage"
    if [ -n "$pinned" ] && [ -n "$need" ]; then
        echo "Stage 2 is $pinned, set by M1N1 in $M1N1_CONFIG, not the aura package's."
        echo "This kernel needs aura $need or newer; with an older one, the speakers stay off."
    fi
    if [ -n "$(m1n1_setting DTBS)" ]; then
        echo "$STAGE2 takes its device trees from DTBS in $M1N1_CONFIG."
    else
        check_dtb "$size"
    fi
}

# Removes the files rescue.sh wrote, by name.
remove_folder() {
    cd /
    # macOS can leave ._ and .DS_Store files on FAT.
    for name in $KERNEL_PKG $KERNEL_PKG.sig $USERPAGES_PKG $USERPAGES_PKG.sig $AURA_PKG $AURA_PKG.sig \
        SHA256SUMS install.sh .DS_Store; do
        rm -f "$DIR/$name" "$DIR/._$name"
    done
    if rmdir "$DIR" 2>/dev/null; then
        rm -f "$(dirname "$DIR")/._$(basename "$DIR")"
    else
        echo "$DIR holds other files, so it stays."
    fi
}

reboot_now() {
    echo
    echo "Done: kernel $NEW is installed."
    if [ "$YES" != 1 ]; then
        printf 'Reboot now to start it? [Y/n] '
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
    systemctl reboot || echo "Reboot when you can with: systemctl reboot"
}

main() {
    YES=0
    for arg in "$@"; do
        case $arg in
        -y | --yes) YES=1 ;;
        *) die "unknown option: $arg" ;;
        esac
    done
    DIR=$(cd "$(dirname "$0")" && pwd)
    START=$(date +%s)

    check_system
    verify
    plan
    confirm
    install_kernel
    check_boot_chain
    remove_folder
    reboot_now
}

# Last, so a truncated copy runs nothing.
main "$@"
EOF
    } >"$TMP/install.sh"
}

copy_to_esp() {
    say "Copying to $ESP_DEV"
    mount_writable
    remove_old_copy
    dir=$ESP_MNT/$FOLDER
    mkdir "$dir"
    # The list first, so a rerun can clear an interrupted copy, and the
    # installer last.
    for name in SHA256SUMS $NAMES install.sh; do
        cp -X "$TMP/$name" "$dir/$name" || die "couldn't write $dir/$name"
    done
    # FAT keeps the attributes macOS gives new files in ._ files, which would
    # stop install.sh from removing the folder.
    for name in $NAMES SHA256SUMS install.sh; do
        rm -f "$dir/._$name"
    done
    rm -f "$ESP_MNT/._$FOLDER"
    (cd "$dir" && shasum -a 256 -c --status SHA256SUMS && cmp -s install.sh "$TMP/install.sh") ||
        die "the copy on $ESP_DEV doesn't match; run this again"
    sync
}

finish() {
    if [ "$KIND" = alarm ]; then
        cat <<EOF

Done: kernel $KREL is on the EFI system partition $ESP_DEV.

To install it, start up in this Mac's Aurora Arch Linux ARM install, open a
terminal and run:

    sudo sh /boot/efi/$FOLDER/install.sh

It checks the packages' signatures against pacman's keyring, installs them
with pacman without a network, checks that the initramfs, GRUB and
m1n1/boot.bin were updated, and removes the folder.
EOF
        return
    fi
    cat <<EOF

Done: kernel $KREL is on the EFI system partition $ESP_DEV.

To install it, start up in this Mac's Aurora Fedora install, open a terminal
and run:

    sudo sh /boot/efi/$FOLDER/install.sh

It checks the packages' signatures, installs them without a network, makes the
kernel GRUB's default, updates m1n1/boot.bin and removes the folder.
EOF
}

main() {
    YES=0 FEDORA='' VERSION='' ESP_DEV='' TEST_DISKS='' TMP='' MOUNTED='' NAMES='' WANT=''
    while [ $# -gt 0 ]; do
        case $1 in
        -y | --yes) YES=1 ;;
        --alarm) WANT=alarm ;;
        --fedora | --version | --esp | --test-disk)
            [ $# -ge 2 ] || die "$1 needs a value"
            case $1 in
            --fedora) FEDORA=$2 ;;
            --version) VERSION=${2%%.fc*} ;;
            --esp) ESP_DEV=${2#/dev/} ;;
            # For tests: look at this attached disk image instead of the internal disk.
            --test-disk) TEST_DISKS="$TEST_DISKS ${2#/dev/}" ;;
            esac
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *) die "unknown option: $1" ;;
        esac
        shift
    done
    case $VERSION in
    '' | [0-9]*-[0-9]*) ;;
    *) die "--version takes a kernel version and release, for example $WIFI_FIX (Arch Linux ARM: $ALARM_WIFI_FIX)" ;;
    esac
    if [ -n "$FEDORA" ]; then
        [ "$WANT" != alarm ] || die "--fedora and --alarm can't be used together"
        WANT=fedora
    fi

    check_macos
    trap cleanup EXIT
    trap 'exit 130' INT TERM HUP
    # sh may be reading this script from a pipe; keep child processes off it.
    exec </dev/null

    find_esps
    choose_esp
    if [ "$KIND" = alarm ]; then
        choose_alarm_kernel
    else
        choose_fedora
        choose_kernel
    fi
    download
    check_space
    if [ "$KIND" = alarm ]; then
        write_alarm_installer
    else
        write_installer
    fi
    confirm
    copy_to_esp
    finish
}

# Last, so a truncated download runs nothing.
main "$@"
