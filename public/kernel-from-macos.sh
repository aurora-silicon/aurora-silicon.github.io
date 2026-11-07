#!/bin/sh
# Updates the kernel of an Aurora Fedora Remix install that has no network,
# from macOS on the same Mac. Run it in macOS:
#
#   curl -fsSL https://aurorasilicon.org/kernel-from-macos.sh | sh
#
# It downloads the kernel from Aurora's package feed and copies it, with an
# installer, to the install's EFI system partition. Then start Linux and run:
#
#   sudo sh /boot/efi/aurora-kernel/install.sh
#
# Options (after "sh -s --" when piped):
#   --version 7.3.0-20   a kernel other than the newest in the feed
#   --fedora 44|45       the install's Fedora release, if it isn't detected
#   --esp disk0s5        the install's EFI system partition, if there are several;
#                        with --fedora, also one that doesn't look like Fedora's
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

say() { printf '\n==> %s\n' "$*"; }
warn() { printf '\nwarning: %s\n' "$*" >&2; }
die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<EOF
usage: sh kernel-from-macos.sh [--version V-R] [--fedora 44|45] [--esp DISK] [--yes]

Copies an Aurora kernel to an Aurora Fedora install's EFI system partition, to
install from Linux with no network: sudo sh /boot/efi/$FOLDER/install.sh
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
    [ "$(uname -s)" = Darwin ] || die "run this in macOS; in Linux with a network, use: sudo dnf upgrade kernel-aurora"
    [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = 1 ] || die "this script is for Apple Silicon Macs"
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
    for name in $NAMES disks.plist part.plist efi.list esp.list channels.json tags.json release.sums SHA256SUMS install.sh candidates; do
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

# Mounts each EFI partition read-only if needed and keeps the ones holding a
# Stage 2 and a Fedora GRUB, one per line: disk|name|size MB|Fedora|mount
# point|fedora or other. With --esp, only that partition, Fedora or not.
find_esps() {
    say "Looking for Aurora Fedora installs"
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
            diskutil mount readOnly -mountOptions nobrowse "$dev" >/dev/null || continue
            MOUNTED="$MOUNTED $dev"
            part_info "$dev" || continue
            mnt=$(pget "$TMP/part.plist" MountPoint) || continue
        fi
        [ -f "$mnt/m1n1/boot.bin" ] || continue
        kind=other
        [ ! -d "$mnt/EFI/fedora" ] || kind=fedora
        [ "$kind" = fedora ] || [ -n "$ESP_DEV" ] || continue
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
        die "no Aurora Fedora install found: none of this Mac's EFI system partitions holds EFI/fedora and m1n1/boot.bin"
    elif [ "$count" = 1 ]; then
        line=$(cat "$TMP/candidates")
    else
        echo
        echo "This Mac has $count Aurora Fedora installs, each with its own EFI system partition:"
        echo
        awk -F'|' '{ printf "  %d) %-9s  %-14s  %5s MB  Fedora %s\n", NR, $1, $2, $3, ($4 == "" ? "unknown" : $4) }' "$TMP/candidates"
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
    if [ "$(echo "$line" | cut -d'|' -f6)" != fedora ]; then
        [ -n "$FEDORA" ] ||
            die "$ESP_DEV has no EFI/fedora, so it doesn't look like an Aurora Fedora install; to use it anyway, also pass --fedora 44 or --fedora 45"
        warn "$ESP_DEV (\"$ESP_NAME\") has no EFI/fedora, so it doesn't look like a Fedora install.
Using it because --esp and --fedora were given. install.sh only installs on Aurora Fedora $FEDORA."
    fi

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
}

download() {
    say "Downloading kernel $KREL from release $TAG"
    for name in $NAMES; do
        curl -fL --retry 3 --progress-bar -o "$TMP/$name" "$RELEASES/$TAG/$name" || die "couldn't download $name"
    done
    (cd "$TMP" && shasum -a 256 -c --status SHA256SUMS) || die "a download doesn't match its checksum; run this again"
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
    if older_than "$VERSION" "$WIFI_FIX"; then
        warn "kernel $VERSION is older than $WIFI_FIX and doesn't have the Wi-Fi fix for Macs with a
BCM4378 (M1 MacBook Air, 13-inch M1 and M2 MacBook Pro, and probably M1 Mac mini).
On those Macs, Wi-Fi in Linux stays broken with this kernel."
    fi
    cat <<EOF

This copies Aurora kernel $KREL ($((SIZE_KB / 1024)) MB, release $TAG)
for Fedora $FEDORA to the folder $FOLDER on the EFI system partition
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
    [ ! -f "$dir/SHA256SUMS" ] || old=$(awk '$2 ~ /^[A-Za-z0-9._+~-]+\.rpm$/ { print $2 }' "$dir/SHA256SUMS")
    for name in $old SHA256SUMS install.sh .DS_Store; do
        rm -f "$dir/$name" "$dir/._$name"
    done
    rmdir "$dir" 2>/dev/null || die "$dir holds files this script didn't write; move them away and run this again"
}

write_installer() {
    {
        cat <<'EOF'
#!/bin/sh
# Installs the Aurora kernel that kernel-from-macos.sh copied to this folder,
# without a network, then removes the folder. Run it in Linux:
#
#   sudo sh /boot/efi/aurora-kernel/install.sh
#
# --yes answers yes to both questions, including the reboot.

set -eu

EOF
        echo "# Written by kernel-from-macos.sh."
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
    # shellcheck disable=SC1091
    release=$(. /etc/os-release && echo "${VERSION_ID:-}")
    [ "$release" = "$FEDORA" ] ||
        die "this kernel is for Fedora $FEDORA, but this install runs Fedora ${release:-unknown}; in macOS, run kernel-from-macos.sh again with --fedora $release"
    rpm -q --quiet kernel-aurora-core || die "this isn't an Aurora Fedora install: kernel-aurora-core isn't installed"
    findmnt -n "$ESP" >/dev/null || die "the EFI system partition isn't mounted at $ESP"
}

verify() {
    say "Checking the packages"
    cd "$DIR"
    sha256sum -c --quiet SHA256SUMS || die "files in $DIR are damaged; in macOS, run kernel-from-macos.sh again"
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

# Removes the files kernel-from-macos.sh wrote, by name.
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
    YES=0 FEDORA='' VERSION='' ESP_DEV='' TEST_DISKS='' TMP='' MOUNTED='' NAMES=
    while [ $# -gt 0 ]; do
        case $1 in
        -y | --yes) YES=1 ;;
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
    *) die "--version takes a kernel version and release, for example $WIFI_FIX" ;;
    esac

    check_macos
    trap cleanup EXIT
    trap 'exit 130' INT TERM HUP
    # sh may be reading this script from a pipe; keep child processes off it.
    exec </dev/null

    find_esps
    choose_esp
    choose_fedora
    choose_kernel
    download
    check_space
    write_installer
    confirm
    copy_to_esp
    finish
}

# Last, so a truncated download runs nothing.
main "$@"
