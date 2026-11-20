#!/bin/sh
# SPDX-License-Identifier: MIT
#
# pmp.sh: turn the PMP (the SoC's Power Management Processor) on or off on an
# M1 Max Mac running Aurora Linux, and show whether it is on.
#
#   curl -fLO https://aurorasilicon.org/pmp.sh
#   sh pmp.sh status
#   sudo sh pmp.sh on        # shows what would change, then asks
#   sudo sh pmp.sh off
#
# Options: --dry-run shows what would change and writes nothing; -y or --yes
# doesn't ask. Piped: curl -fsSL https://aurorasilicon.org/pmp.sh | sudo sh -s -- on
#
# EXPERIMENTAL. Nobody has started an M1 Max with the PMP on yet; M1 Pro
# MacBook Pros already run with it on. For the MacBook Pro 14" and 16" with M1
# Max (J314c, J316c) and the Mac Studio with M1 Max (J375c), on Aurora Fedora
# and Aurora Arch Linux ARM (including Omarchy). Not NixOS, not M1 Ultra.
#
# What `on` does
#   Aurora's kernel enables the PMP on Macs whose device tree it builds with
#   APPLE_USE_PMP, and it doesn't build the M1 Max trees that way yet. `on`
#   makes the same changes to this Mac's installed tree (for example
#   t6001-j316c.dtb) with fdtput: it adds the pmp alias, which makes aura
#   (Stage 2) give the PMP this Mac's board data and enable it at boot; it
#   powers DCP, DCPEXT0/1, ISP and AVD through their PMP report entries; and
#   it enables the JPEG report entry. Anything that isn't exactly as expected
#   stops it before it changes anything. It saves the original tree, then runs
#   update-m1n1, which rebuilds Stage 2 (m1n1/boot.bin on the EFI system
#   partition) with the device trees in it. `off` puts the original back and
#   runs update-m1n1 again. It never reboots by itself.
#
# Kernel updates turn the PMP off again: a new kernel brings its own unchanged
# device trees, and update-m1n1 rebuilds Stage 2 from them. Run
# `sudo sh pmp.sh on` again after each kernel update; `status` shows the state.
#
# RECOVERY, if Linux doesn't start after `on` (pmp.sh says which case applies):
#   Trial: with a recent aura Stage 1, update-m1n1 installs the new Stage 2 as
#     a one-time trial (m1n1/boot.bin.next) and keeps the working one. aura's
#     watchdog restarts a trial that hangs, and Aurora restarts one that hasn't
#     confirmed itself within about 12 minutes. You can also hold the power
#     button until the Mac turns off and start it again. Each way, the Mac then
#     starts the previous Stage 2, without the PMP. Once in Linux, run
#     `sudo sh pmp.sh off` so that the next update doesn't install it again.
#   Direct: the new Stage 2 replaced m1n1/boot.bin. pmp.sh saved the previous
#     one as m1n1/boot.bin.pre-pmp on the same partition (update-m1n1 also
#     keeps it as boot.bin.old until it next runs). Hold the power button at
#     startup and start macOS, or Options > recoveryOS > Utilities > Terminal.
#     In Terminal (in recoveryOS, leave out sudo):
#       diskutil list                # the EFI partition of the Aurora install
#       sudo diskutil mount disk0s4  # that partition; it says where it mounted
#       cd /Volumes/EFI/m1n1         # that place; boot.bin.pre-pmp is here
#       sudo cp boot.bin.pre-pmp boot.bin
#     Then start Aurora and run `sudo sh pmp.sh off`.
#   Choosing an older kernel in GRUB doesn't help: every GRUB entry starts with
#   the one device tree inside Stage 2.
#
# Testing only: PMP_SH_ROOT=<dir> works on a copy of a system under <dir>
# (no root needed, mounts nothing, never runs the system's update-m1n1;
# PMP_SH_UPDATE_M1N1=<command> stands in for it). PMP_SH_ESP=<dir> names the
# EFI system partition's directory.

set -eu

MIN_AURA=1.0.0b12
PMP_NODE=/soc/pmp@28e700000
REPORT=/soc/pmp_report@28e3c0000
# The consumers APPLE_USE_PMP powers through a PMP report entry instead of their
# PMGR power domain: node, its compatible, and the entry's unit address and label.
SWITCHES='/soc/dcp@38bc00000 apple,t6000-dcp c pmp-disp0
/soc/dcp@289c00000 apple,t6000-dcpext d pmp-dispext0
/soc/dcp@28cc00000 apple,t6000-dcpext e pmp-dispext1
/soc/isp@384000000 apple,t6000-isp b pmp-isp-sys
/soc/avd@287080000 apple,t6000-avd 11 pmp-avd-sys'
# The report entry APPLE_USE_PMP enables: it drops status = "disabled".
JPG_UNIT=13
JPG_LABEL=pmp-jpg

ROOT=${PMP_SH_ROOT:-}
ROOT=${ROOT%/}
STATE=$ROOT/var/lib/aurora-pmp
TMP=
ESP=
ESP_MOUNTED=

say() { printf '%s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
die() {
    printf 'pmp.sh: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'END'
Usage: pmp.sh [--dry-run] [-y] status|on|off

  status   show whether the PMP is on now, and in the installed device trees
  on       turn the PMP on (M1 Max: J314c, J316c, J375c); takes effect at reboot
  off      put the original device tree back; takes effect at reboot

  --dry-run  show what would change; write nothing
  -y, --yes  don't ask before changing anything

Run on and off with sudo. Read the RECOVERY notes at the top of this script
before turning the PMP on.
END
}

# --- device trees ----------------------------------------------------------

# fdtget that prints nothing (and fails) when the node or property is missing.
get() { fdtget "$@" 2>/dev/null; }

sha() { sha256sum "$1" | cut -d' ' -f1; }

# Succeeds if node $2 of tree $1 exists with exactly that path. fdtget alone
# resolves /soc to a soc@... node, so check every component by name.
node_exists() {
    ne_parent=
    ne_rest=${2#/}
    while [ -n "$ne_rest" ]; do
        ne_name=${ne_rest%%/*}
        get -l "$1" "${ne_parent:-/}" | grep -qxF "$ne_name" || return 1
        ne_parent=$ne_parent/$ne_name
        case $ne_rest in */*) ne_rest=${ne_rest#*/} ;; *) ne_rest= ;; esac
    done
}

# Succeeds if node $2 of tree $1 lists compatible $3.
has_compat() {
    get -t s "$1" "$2" compatible | tr ' ' '\n' | grep -qxF "$3"
}

# The highest phandle in tree $1, in decimal.
max_phandle() {
    mp=0
    for mp_h in $(dtc -q -I dtb -O dts "$1" | sed -n 's/^[[:space:]]*phandle = <\(0x[0-9a-f]*\)>;$/\1/p'); do
        [ $((mp_h)) -le "$mp" ] || mp=$((mp_h))
    done
    echo "$mp"
}

# Checks report entry $2 (unit address) of tree $1, labelled $3. Prints the
# phandle of its parent power domain, or why it isn't as expected (and fails).
entry_parent() {
    ep=$REPORT/report@$2
    node_exists "$1" "$ep" || { echo "no $ep"; return 1; }
    has_compat "$1" "$ep" apple,t6000-pmp-v2-report-entry || { echo "$ep isn't a PMP report entry"; return 1; }
    [ "$(get -t s "$1" "$ep" label)" = "$3" ] || { echo "$ep isn't labelled $3"; return 1; }
    [ "$(get -t u "$1" "$ep" reg)" = "$((0x$2))" ] || { echo "$ep has another reg"; return 1; }
    [ "$(get -t u "$1" "$ep" '#power-domain-cells')" = 0 ] ||
        { echo "$ep has #power-domain-cells other than 0"; return 1; }
    ep_parent=$(get -t u "$1" "$ep" power-domains) || { echo "$ep has no power-domains"; return 1; }
    case $ep_parent in
    *' '* | '') echo "$ep has more than one power domain"; return 1 ;;
    esac
    echo "$ep_parent"
}

# Prints "off" for this board's tree as the kernel builds it, or "on" for one
# with APPLE_USE_PMP's changes. Anything else fails and prints why.
dt_state() {
    f=$1
    dtc -q -I dtb -O dtb -o /dev/null "$f" 2>/dev/null || { echo "dtc can't read it"; return 1; }
    has_compat "$f" / "apple,$BOARD" || { echo "it isn't the $BOARD tree"; return 1; }
    has_compat "$f" / apple,t6001 || { echo "it isn't a T6001 tree"; return 1; }
    if get -l "$f" / | grep -q '^soc@'; then
        echo "it has a soc@ node next to /soc"
        return 1
    fi
    if dtc -q -I dtb -O dts "$f" | grep -q 'linux,phandle'; then
        echo "it uses linux,phandle"
        return 1
    fi
    for ds_n in /aliases $PMP_NODE $REPORT; do
        node_exists "$f" "$ds_n" || { echo "no $ds_n"; return 1; }
    done
    has_compat "$f" $PMP_NODE apple,t6000-pmp-v2 || { echo "$PMP_NODE isn't the T6000 PMP"; return 1; }
    has_compat "$f" $REPORT apple,t6000-pmp-v2-report || { echo "$REPORT isn't the PMP report"; return 1; }
    [ "$(get -t s "$f" $PMP_NODE status)" = disabled ] ||
        { echo "$PMP_NODE isn't status = \"disabled\" (aura enables it at boot)"; return 1; }
    ds_on=0 ds_off=0
    while read -r ds_node ds_compat ds_unit ds_label; do
        ds_parent=$(entry_parent "$f" "$ds_unit" "$ds_label") || { echo "$ds_parent"; return 1; }
        node_exists "$f" "$ds_node" || { echo "no $ds_node"; return 1; }
        has_compat "$f" "$ds_node" "$ds_compat" || { echo "$ds_node isn't $ds_compat"; return 1; }
        ds_pd=$(get -t u "$f" "$ds_node" power-domains) || { echo "$ds_node has no power-domains"; return 1; }
        ds_first=${ds_pd%% *}
        ds_ph=$(get -t u "$f" "$REPORT/report@$ds_unit" phandle || true)
        if [ "$ds_first" = "$ds_parent" ]; then
            ds_off=$((ds_off + 1))
        elif [ -n "$ds_ph" ] && [ "$ds_first" = "$ds_ph" ]; then
            ds_on=$((ds_on + 1))
        else
            echo "$ds_node's power domain is neither $ds_label's nor its parent's"
            return 1
        fi
    done <<END
$SWITCHES
END
    ds_parent=$(entry_parent "$f" $JPG_UNIT $JPG_LABEL) || { echo "$ds_parent"; return 1; }
    case $(get -t s "$f" "$REPORT/report@$JPG_UNIT" status || echo '(none)') in
    disabled) ds_off=$((ds_off + 1)) ;;
    '(none)') ds_on=$((ds_on + 1)) ;;
    *) echo "$JPG_LABEL has an unexpected status"; return 1 ;;
    esac
    ds_alias=$(get -t s "$f" /aliases pmp || echo '(none)')
    case $ds_alias in
    '(none)') ds_off=$((ds_off + 1)) ;;
    "$PMP_NODE") ds_on=$((ds_on + 1)) ;;
    *) echo "its pmp alias names $ds_alias"; return 1 ;;
    esac
    if [ "$ds_on" = 0 ]; then
        echo off
    elif [ "$ds_off" = 0 ]; then
        echo on
    else
        echo "it is partly changed ($ds_on of $((ds_on + ds_off)) changes present)"
        return 1
    fi
}

# Applies APPLE_USE_PMP's changes to tree $1, which dt_state found "off".
# With $2 = show, only prints them.
dt_on() {
    f=$1 on_show=${2:-}
    on_next=$(max_phandle "$f")
    while read -r on_node _ on_unit on_label; do
        on_entry=$REPORT/report@$on_unit
        on_ph=$(get -t u "$f" "$on_entry" phandle || true)
        on_new=
        if [ -z "$on_ph" ]; then
            on_next=$((on_next + 1))
            on_ph=$on_next on_new=", new phandle"
            [ -n "$on_show" ] || fdtput -t u "$f" "$on_entry" phandle "$on_ph"
        fi
        on_pd=$(get -t u "$f" "$on_node" power-domains)
        on_rest=${on_pd#* }
        [ "$on_rest" != "$on_pd" ] || on_rest=
        if [ -n "$on_show" ]; then
            printf '    %s: power-domains <%#x%s> -> %s report entry <%#x>%s\n' "$on_node" \
                "${on_pd%% *}" "${on_rest:+ ...}" "$on_label" "$on_ph" "$on_new"
        else
            # shellcheck disable=SC2086
            fdtput -t u "$f" "$on_node" power-domains "$on_ph" $on_rest
        fi
    done <<END
$SWITCHES
END
    if [ -n "$on_show" ]; then
        say "    $REPORT/report@$JPG_UNIT ($JPG_LABEL): remove status = \"disabled\""
        say "    /aliases: add pmp = \"$PMP_NODE\" (aura then enables the PMP at boot)"
        return 0
    fi
    fdtput -d "$f" "$REPORT/report@$JPG_UNIT" status
    fdtput -t s "$f" /aliases pmp "$PMP_NODE"
}

# Undoes dt_on on tree $1, for when no saved original matches. The phandles
# it added stay; nothing refers to them.
dt_off() {
    f=$1
    while read -r off_node _ off_unit off_label; do
        off_parent=$(entry_parent "$f" "$off_unit" "$off_label") || die "$off_parent"
        off_pd=$(get -t u "$f" "$off_node" power-domains)
        off_rest=${off_pd#* }
        [ "$off_rest" != "$off_pd" ] || off_rest=
        # shellcheck disable=SC2086
        fdtput -t u "$f" "$off_node" power-domains "$off_parent" $off_rest
    done <<END
$SWITCHES
END
    fdtput -t s "$f" "$REPORT/report@$JPG_UNIT" status disabled
    fdtput -d "$f" /aliases pmp
}

# --- this system -----------------------------------------------------------

chosen() { tr -d '\0' 2>/dev/null <"$ROOT/proc/device-tree/chosen/$1" || true; }

read_board() {
    rb_c=$ROOT/proc/device-tree/compatible
    [ -r "$rb_c" ] || die "can't read $rb_c; run pmp.sh in Aurora Linux on the Mac"
    COMPAT=$(tr '\0' ' ' <"$rb_c")
    COMPAT=${COMPAT% }
    MODEL=$(tr -d '\0' 2>/dev/null <"$ROOT/proc/device-tree/model" || echo "this Mac")
    BOARD=
    for rb_b in $COMPAT; do
        case $rb_b in
        apple,j*) BOARD=${rb_b#apple,} && break ;;
        esac
    done
    case " $COMPAT " in
    *" apple,t6001 "*) SOC=t6001 ;;
    *" apple,t6000 "*) SOC=t6000 ;;
    *" apple,t6002 "*) SOC=t6002 ;;
    *" apple,t8103 "*) SOC=t8103 ;;
    *) SOC=other ;;
    esac
    SUPPORTED='' DTB=''
    case $SOC:$BOARD in
    t6001:j314c | t6001:j316c | t6001:j375c) SUPPORTED=1 DTB=t6001-$BOARD.dtb ;;
    esac
}

refuse_board() {
    case $SOC in
    t6000) die "$MODEL is an M1 Pro: Aurora's kernel builds its device tree with the PMP on already. 'sh pmp.sh status' shows it; if it says off, update the kernel." ;;
    t6002) die "$MODEL is an M1 Ultra: its device tree doesn't build with APPLE_USE_PMP (the second die's AVD has no PMP report entry), so pmp.sh doesn't support it." ;;
    t8103) die "$MODEL is an M1: Aurora's kernel has no PMP driver for the M1 (T8103), so there is nothing to turn on." ;;
    esac
    die "pmp.sh is only for M1 Max Macs (J314c, J316c, J375c); this is $MODEL ($COMPAT)"
}

detect_layout() {
    LAYOUT='' M1N1_CONF='' M1N1_DEFAULT=''
    if [ -f "$ROOT/usr/libexec/aurora/bootchain_arch.py" ]; then
        LAYOUT=arch M1N1_CONF=/etc/default/update-m1n1 M1N1_DEFAULT=/usr/lib/asahi-boot/m1n1.bin
    elif [ -f "$ROOT/usr/libexec/aurora/bootchain.py" ]; then
        LAYOUT=fedora M1N1_CONF=/etc/sysconfig/update-m1n1 M1N1_DEFAULT=/usr/lib64/m1n1/m1n1.bin
    elif grep -qs '^ID=nixos' "$ROOT/etc/os-release"; then
        LAYOUT=nixos
    fi
    if [ -n "$ROOT" ]; then
        UPDATER=${PMP_SH_UPDATE_M1N1:-}
    else
        UPDATER=$(command -v update-m1n1 2>/dev/null || true)
    fi
}

need_layout() {
    case $LAYOUT in
    fedora | arch) ;;
    nixos) die "on NixOS, Stage 2 is built from the kernel's read-only device trees at every nixos-rebuild, so pmp.sh can't change them. The PMP will come with a kernel that builds this Mac's tree with APPLE_USE_PMP." ;;
    *) die "this isn't an Aurora Fedora or Arch Linux ARM install: /usr/libexec/aurora/bootchain.py (update-m1n1) is missing" ;;
    esac
    [ -n "$ROOT" ] || [ -n "$UPDATER" ] || die "update-m1n1 is missing; it rebuilds Stage 2 with the device trees"
}

need_tools() {
    nt_missing=
    for nt_t in dtc fdtget fdtput sha256sum od findmnt; do
        command -v "$nt_t" >/dev/null 2>&1 || nt_missing="$nt_missing $nt_t"
    done
    [ -n "$nt_missing" ] || return 0
    case $LAYOUT in
    fedora) nt_how="sudo dnf install dtc" ;;
    arch) nt_how="sudo pacman -S dtc" ;;
    *) nt_how="install the dtc package" ;;
    esac
    die "missing:$nt_missing. dtc, fdtget and fdtput come with the dtc package: $nt_how"
}

# Prints a setting from update-m1n1's configuration, read as update-m1n1 does.
m1n1_setting() {
    [ -f "$ROOT$M1N1_CONF" ] || return 0
    (
        set +eu
        # shellcheck disable=SC1090
        . "$ROOT$M1N1_CONF" >/dev/null 2>&1
        eval "printf '%s' \"\${$1-}\""
    )
}

check_m1n1_config() {
    [ -z "$(m1n1_setting M1N1_UPDATE_DISABLED)" ] ||
        die "update-m1n1 is turned off (M1N1_UPDATE_DISABLED in $M1N1_CONF), so Stage 2 wouldn't take the change"
    cm_dtbs=$(m1n1_setting DTBS)
    case $LAYOUT:$cm_dtbs in
    fedora: | fedora:/boot/dtb | arch:) ;;
    *) die "update-m1n1 takes its device trees from DTBS=\"$cm_dtbs\" in $M1N1_CONF, not from the kernel; pmp.sh only changes the kernel's own" ;;
    esac
    cm_src=$(m1n1_setting SOURCE)
    cm_m1n1=$(m1n1_setting M1N1)
    STAGE2_BIN=${cm_m1n1:-${cm_src:+$cm_src/m1n1.bin}}
    STAGE2_BIN=${STAGE2_BIN:-$M1N1_DEFAULT}
}

# The aura version inside a Stage 2 image or payload, or nothing.
aura_version_in() {
    LC_ALL=C grep -a -o '##aura_ver##[[:alnum:]._+-]*' "$1" 2>/dev/null | head -n 1 | sed 's/^##aura_ver##//'
}

aura_norm() {
    an=${1#v}
    an=${an%%-*}
    case $an in
    '' | *[!0-9.b]*) ;;
    *b*) echo "$an" ;;
    *) echo "${an}b999999" ;;
    esac
}

# Succeeds if aura version $1 is at least $2 (1.0.0b12, 1.0.0b13.1, 1.0.0, ...).
aura_at_least() {
    av_a=$(aura_norm "$1") av_b=$(aura_norm "$2")
    [ -n "$av_a" ] || return 1
    [ "$(printf '%s\n%s\n' "$av_a" "$av_b" | sort -V | head -n 1)" = "$av_b" ]
}

# The copies of this board's tree for kernel $1 that update-m1n1 reads.
kernel_dtbs() {
    case $LAYOUT in
    arch) kd_l="/usr/lib/modules/$1/dtbs/$DTB" ;;
    *) kd_l="/usr/lib/modules/$1/dtb/apple/$DTB /boot/dtb-$1/apple/$DTB" ;;
    esac
    for kd_f in $kd_l; do
        if [ -f "$ROOT$kd_f" ] && [ ! -L "$ROOT$kd_f" ]; then
            echo "$ROOT$kd_f"
        fi
    done
    return 0
}

# The installed kernels that have this board's tree.
kernels() {
    for k_d in "$ROOT"/usr/lib/modules/*/; do
        k_v=$(basename "$k_d")
        [ -z "$(kernel_dtbs "$k_v")" ] || echo "$k_v"
    done
    return 0
}

# How kernel $1 has driver $2: built-in or module (or fails).
kernel_has() {
    if grep -qs "/$2\\.ko\$" "$ROOT/usr/lib/modules/$1/modules.builtin"; then
        echo built-in
    elif [ -n "$(find "$ROOT/usr/lib/modules/$1/kernel" -name "$2.ko*" 2>/dev/null | head -n 1)" ]; then
        echo module
    else
        return 1
    fi
}

# How kernel $1 has the PMP driver (CONFIG_APPLE_PMP), or fails.
kernel_pmp() {
    kernel_has "$1" pmp-report >/dev/null || return 1
    kernel_has "$1" apple-pmp
}

# --- Stage 2 on the EFI system partition -------------------------------------

esp_open() {
    [ -z "$ESP" ] || return 0
    if [ -n "${PMP_SH_ESP:-}" ]; then
        ESP=$PMP_SH_ESP
    elif [ -n "$ROOT" ]; then
        ESP=$ROOT/boot/efi
    else
        eo_uuid=$(chosen asahi,efi-system-partition)
        if [ -n "$eo_uuid" ]; then
            ESP=$(findmnt -nro TARGET -S "PARTUUID=$eo_uuid" 2>/dev/null | head -n 1 || true)
            if [ -z "$ESP" ] && [ "$(id -u)" = 0 ]; then
                mkdir -p /run/pmp-sh-esp
                if mount -o ro "PARTUUID=$eo_uuid" /run/pmp-sh-esp; then
                    ESP=/run/pmp-sh-esp ESP_MOUNTED=1
                fi
            fi
        else
            for eo_d in /boot/efi /boot; do
                if [ -e "$eo_d/m1n1" ]; then
                    ESP=$eo_d
                    break
                fi
            done
        fi
    fi
    if [ -z "$ESP" ] || [ ! -r "$ESP/m1n1/boot.bin" ]; then
        esp_close
        return 1
    fi
}

esp_close() {
    if [ -n "$ESP_MOUNTED" ]; then
        umount /run/pmp-sh-esp 2>/dev/null || true
        rmdir /run/pmp-sh-esp 2>/dev/null || true
    fi
    ESP='' ESP_MOUNTED=''
}

hex() { od -An -v -tx1 -j "$2" -N "$3" "$1" | tr -d ' \n'; }

# Prints "offset size" for each device tree in Stage 2 image $1: they follow
# aura one after another, and gzip-compressed U-Boot follows them.
payload_dtbs() {
    pd_f=$1
    pd_first=
    [ ! -f "$ROOT$STAGE2_BIN" ] || pd_first=$(wc -c <"$ROOT$STAGE2_BIN" | tr -d ' ')
    pd_more=$(LC_ALL=C grep -obUaP '\xd0\x0d\xfe\xed' "$pd_f" 2>/dev/null | cut -d: -f1 | head -n 4096 || true)
    for pd_s in $pd_first $pd_more; do
        pd_off=$pd_s pd_out=
        while [ "$(hex "$pd_f" "$pd_off" 4)" = d00dfeed ]; do
            pd_size=$((0x$(hex "$pd_f" $((pd_off + 4)) 4)))
            [ "$pd_size" -ge 40 ] || break
            pd_out="$pd_out$pd_off $pd_size
"
            pd_off=$((pd_off + pd_size))
        done
        if [ -n "$pd_out" ] && [ "$(hex "$pd_f" "$pd_off" 2)" = 1f8b ]; then
            printf '%s' "$pd_out"
            return 0
        fi
    done
    return 1
}

# Copies this board's tree out of Stage 2 image $1 into $2.
payload_board_dtb() {
    pb_list=$(payload_dtbs "$1") || return 1
    while read -r pb_off pb_size; do
        tail -c +$((pb_off + 1)) "$1" | head -c "$pb_size" >"$2"
        has_compat "$2" / "apple,$BOARD" && return 0
    done <<END
$pb_list
END
    return 1
}

# Succeeds if Stage 2 image $1 carries exactly device tree $2.
payload_has() {
    ph_sha=$(sha "$2")
    ph_len=$(wc -c <"$2" | tr -d ' ')
    ph_list=$(payload_dtbs "$1") || return 1
    while read -r ph_off ph_size; do
        [ "$ph_size" = "$ph_len" ] || continue
        [ "$(tail -c +$((ph_off + 1)) "$1" | head -c "$ph_size" | sha256sum | cut -d' ' -f1)" = "$ph_sha" ] && return 0
    done <<END
$ph_list
END
    return 1
}

# Says whether Stage 2 image $1 has the PMP on, and whose tree it carries.
describe_payload() {
    dp_t=$TMP/payload.dtb
    payload_board_dtb "$1" "$dp_t" || { echo "no $BOARD device tree found in it"; return 0; }
    dp_state=$(dt_state "$dp_t") || dp_state="unknown ($dp_state)"
    dp_sha=$(sha "$dp_t")
    dp_from=
    for dp_k in $(kernels); do
        for dp_f in $(kernel_dtbs "$dp_k"); do
            if [ "$(sha "$dp_f")" = "$dp_sha" ]; then
                dp_from="$dp_from $dp_k"
                break
            fi
        done
    done
    echo "PMP $dp_state${dp_from:+, the device tree of kernel$dp_from}"
}

trial_armed() {
    [ -n "$ESP" ] && [ -f "$ESP/aura-try" ] && [ -f "$ESP/m1n1/boot.bin.next" ] &&
        [ "$(head -n 1 "$ESP/aura-try")" = armed ]
}

run_update_m1n1() {
    esp_close
    if [ -z "$UPDATER" ]; then
        note "(test root without PMP_SH_UPDATE_M1N1: update-m1n1 not run)"
        return 0
    fi
    step "Running update-m1n1"
    $UPDATER
}

# --- commands ------------------------------------------------------------

running_state() {
    step "Running now: $MODEL ($COMPAT)"
    rs_v=$(chosen asahi,m1n1-stage2-version)
    note "aura Stage 2: ${rs_v:-unknown}"
    rs_dt=$ROOT/proc/device-tree
    if [ -e "$rs_dt/aliases/pmp" ]; then
        note "pmp alias: $(tr -d '\0' <"$rs_dt/aliases/pmp")"
    else
        note "pmp alias: none (this boot's device tree has the PMP off)"
    fi
    rs_node=$(find "$rs_dt/" -maxdepth 2 -name 'pmp@*' 2>/dev/null | head -n 1)
    if [ -n "$rs_node" ]; then
        rs_st=$(tr -d '\0' 2>/dev/null <"$rs_node/status" || echo okay)
        rs_bd=
        [ ! -e "$rs_node/apple,board-id" ] || rs_bd=", with board data from aura"
        note "pmp node: ${rs_node#"$rs_dt"}, status $rs_st$rs_bd"
    fi
    rs_cfg=
    if [ -z "$ROOT" ] && [ -r /proc/config.gz ] && command -v zcat >/dev/null 2>&1; then
        rs_cfg=$(zcat /proc/config.gz | sed -n 's/^CONFIG_APPLE_PMP=//p')
    fi
    note "running kernel $(uname -r): CONFIG_APPLE_PMP=${rs_cfg:-?}"
    rs_drv=$ROOT/sys/bus/platform/drivers/apple_pmp
    rs_bound=$(find "$rs_drv/" -maxdepth 1 -name '*.pmp' 2>/dev/null | head -n 1)
    if [ -n "$rs_bound" ]; then
        note "PMP driver: bound to $(basename "$rs_bound")"
    elif [ -d "$rs_drv" ]; then
        note "PMP driver: loaded, not bound"
    else
        note "PMP driver: not loaded"
    fi
    if [ -z "$ROOT" ]; then
        rs_log=$({ dmesg 2>/dev/null || journalctl -k -b -o cat 2>/dev/null || true; } |
            grep -E 'apple_pmp|apple-pmp|28e700000\.pmp' | tail -n 5 || true)
        if [ -n "$rs_log" ]; then
            note "kernel log:"
            printf '%s\n' "$rs_log" | sed 's/^/      /'
        fi
    fi
}

cmd_status() {
    read_board
    detect_layout
    running_state
    if [ -z "$SUPPORTED" ]; then
        case $SOC in
        t6000) say "This is an M1 Pro: Aurora's kernel builds its tree with the PMP on already." ;;
        *) say "on and off are only for M1 Max Macs (J314c, J316c, J375c)." ;;
        esac
        return 0
    fi
    need_layout
    need_tools
    check_m1n1_config
    TMP=$(mktemp -d "${TMPDIR:-/tmp}/pmp-sh.XXXXXX")
    step "Installed device trees ($DTB)"
    for st_k in $(kernels); do
        st_p=$(kernel_pmp "$st_k") || st_p="missing"
        note "kernel $st_k (PMP driver: $st_p)"
        for st_f in $(kernel_dtbs "$st_k"); do
            st_s=$(dt_state "$st_f") || st_s="unexpected: $st_s"
            note "  ${st_f#"$ROOT"}: PMP $st_s"
        done
    done
    if [ -d "$STATE" ]; then
        note "originals saved by pmp.sh: $(find "$STATE" -name manifest | wc -l | tr -d ' ') set(s) in ${STATE#"$ROOT"}"
    fi
    step "Stage 2"
    st_av=$(aura_version_in "$ROOT$STAGE2_BIN" || true)
    note "aura that update-m1n1 puts in: ${st_av:-unknown} ($STAGE2_BIN)"
    if esp_open; then
        note "m1n1/boot.bin: $(describe_payload "$ESP/m1n1/boot.bin")"
        if trial_armed; then
            note "armed trial m1n1/boot.bin.next, starts once at the next boot: $(describe_payload "$ESP/m1n1/boot.bin.next")"
        fi
        [ -z "$(chosen aurora,trial)" ] || note "this boot is a Stage 2 trial that isn't committed yet"
        [ ! -f "$ESP/m1n1/boot.bin.pre-pmp" ] ||
            note "m1n1/boot.bin.pre-pmp: the Stage 2 from before 'pmp.sh on', for RECOVERY"
    else
        note "can't read m1n1/boot.bin: run with sudo"
    fi
}

common_checks() {
    [ -n "$ROOT" ] || [ "$(uname -m)" = aarch64 ] || die "run pmp.sh in Aurora Linux on the Mac"
    read_board
    detect_layout
    [ -n "$SUPPORTED" ] || refuse_board
    need_layout
    need_tools
    check_m1n1_config
    if [ -z "$ROOT" ] && [ "$(id -u)" != 0 ] && [ "$DRY_RUN" != 1 ]; then
        die "run it as root: sudo sh pmp.sh $CMD"
    fi
    [ ! -e "$ROOT/var/lib/pacman/db.lck" ] || die "pacman is running; try again when it has finished"
    [ -z "$(chosen aurora,trial)" ] ||
        die "this boot is a Stage 2 trial that isn't committed yet; let it commit (or reboot) first"
    if ! esp_open; then
        [ -n "$ROOT" ] || [ "$(id -u)" = 0 ] || die "can't read m1n1/boot.bin on the EFI system partition; run with sudo"
        die "can't find m1n1/boot.bin on the EFI system partition"
    fi
    ! trial_armed || die "a Stage 2 trial (m1n1/boot.bin.next) is waiting for the next boot; reboot first"
    TMP=$(mktemp -d "${TMPDIR:-/tmp}/pmp-sh.XXXXXX")
}

confirm() {
    [ "$YES" != 1 ] || return 0
    printf '\nContinue? [y/N] '
    { read -r cf_answer </dev/tty; } 2>/dev/null || {
        echo
        die "no terminal to ask on; pass -y to continue without asking"
    }
    case $cf_answer in
    y | Y | yes | YES) ;;
    *) die "nothing was changed" ;;
    esac
}

# Fails, before anything is written, unless the directories of files $@ can
# be written to.
need_writable() {
    for nw_f in "$@"; do
        nw_d=$(dirname "$nw_f")
        while [ ! -e "$nw_d" ]; do nw_d=$(dirname "$nw_d"); done
        [ -w "$nw_d" ] || die "can't write to ${nw_d#"$ROOT"}; nothing was changed"
    done
}

# Replaces $1 with the contents of $2 (a copy in the same directory, then a
# rename) and checks the result.
install_file() {
    if_tmp=$(dirname "$1")/.pmp-sh.$$.dtb
    cp -p "$1" "$if_tmp"
    cat "$2" >"$if_tmp"
    mv -f "$if_tmp" "$1"
    if [ -z "$ROOT" ] && command -v restorecon >/dev/null 2>&1; then
        restorecon "$1" 2>/dev/null || true
    fi
    [ "$(sha "$1")" = "$(sha "$2")" ] || die "writing $1 failed; the original is in ${BACKUP:-$STATE}"
}

# The kernels whose tree for this board m1n1/boot.bin carries now.
target_kernels() {
    tk_t=$TMP/live.dtb
    payload_board_dtb "$ESP/m1n1/boot.bin" "$tk_t" ||
        die "m1n1/boot.bin carries no $BOARD device tree; run 'sudo update-m1n1' and check that it succeeds"
    tk_sha=$(sha "$tk_t")
    KERNELS=
    for tk_k in $(kernels); do
        tk_match='' tk_other=''
        for tk_f in $(kernel_dtbs "$tk_k"); do
            if [ "$(sha "$tk_f")" = "$tk_sha" ]; then tk_match=1; else tk_other=$tk_f; fi
        done
        [ -n "$tk_match" ] || continue
        [ -z "$tk_other" ] ||
            die "${tk_other#"$ROOT"} differs from kernel $tk_k's other copy; run 'sudo update-m1n1' and check that it succeeds"
        KERNELS="$KERNELS $tk_k"
    done
    [ -n "$KERNELS" ] ||
        die "m1n1/boot.bin's $BOARD device tree is no installed kernel's; run 'sudo update-m1n1' and check that it succeeds"
}

# Puts back every original in backup set $1 whose changed copy is in place.
restore_backup() {
    [ -f "$1/manifest" ] || return 0
    while read -r rb_name rb_orig rb_new rb_path; do
        [ -f "$ROOT$rb_path" ] && [ "$(sha "$ROOT$rb_path")" = "$rb_new" ] || continue
        [ "$(sha "$1/$rb_name")" = "$rb_orig" ] || die "$1/$rb_name is damaged"
        install_file "$ROOT$rb_path" "$1/$rb_name"
        note "$rb_path: original restored"
    done <"$1/manifest"
}

# Prints the saved original of $1 whose changed copy is in place now, or fails.
find_original() {
    fo_sha=$(sha "$1")
    for fo_dir in $(find "$STATE" -name manifest 2>/dev/null | sort -r | sed 's|/manifest$||'); do
        while read -r fo_name fo_orig fo_new fo_path; do
            [ "$ROOT$fo_path" = "$1" ] && [ "$fo_new" = "$fo_sha" ] || continue
            [ "$(sha "$fo_dir/$fo_name")" = "$fo_orig" ] || continue
            echo "$fo_dir/$fo_name"
            return 0
        done <"$fo_dir/manifest"
    done
    return 1
}

cmd_on() {
    common_checks
    step "Checking"
    on_av=$(aura_version_in "$ROOT$STAGE2_BIN" || true)
    [ -n "$on_av" ] || die "$STAGE2_BIN isn't aura; Aurora's Stage 2 is needed"
    aura_at_least "$on_av" "$MIN_AURA" ||
        die "the aura that update-m1n1 puts in Stage 2 is $on_av; the PMP needs $MIN_AURA or newer. Update the system and try again"
    note "aura for the new Stage 2: $on_av ($STAGE2_BIN); running now: $(chosen asahi,m1n1-stage2-version)"
    target_kernels
    FILES=
    for on_k in $KERNELS; do
        on_drv=$(kernel_pmp "$on_k") || die "kernel $on_k has no PMP driver (CONFIG_APPLE_PMP); update the kernel first"
        note "m1n1/boot.bin carries the device trees of kernel $on_k (PMP driver: $on_drv)"
        FILES="$FILES $(kernel_dtbs "$on_k" | tr '\n' ' ')"
    done
    CHANGE='' i=0 WANT=''
    for on_f in $FILES; do
        on_s=$(dt_state "$on_f") || die "${on_f#"$ROOT"} isn't as expected: $on_s. Nothing was changed"
        note "${on_f#"$ROOT"}: PMP $on_s"
        WANT=${WANT:-$on_f}
        [ "$on_s" = off ] || continue
        i=$((i + 1))
        cp "$on_f" "$TMP/new-$i.dtb"
        dt_on "$TMP/new-$i.dtb"
        on_t=$(dt_state "$TMP/new-$i.dtb") || true
        [ "$on_t" = on ] || die "the changed tree doesn't check out ($on_t); nothing was changed"
        [ "$i" != 1 ] || WANT=$TMP/new-1.dtb
        CHANGE="$CHANGE $on_f"
    done
    if [ -z "$CHANGE" ] && payload_has "$ESP/m1n1/boot.bin" "$WANT"; then
        say
        say "The PMP is on already, in the device tree and in Stage 2. Reboot if this boot doesn't have it yet."
        return 0
    fi
    on_live=$(describe_payload "$ESP/m1n1/boot.bin")

    step "Plan"
    if [ -n "$CHANGE" ]; then
        say "Change this Mac's device tree as APPLE_USE_PMP does, in:"
        for on_f in $CHANGE; do note "${on_f#"$ROOT"}"; done
        say "Changes:"
        on_one=${CHANGE# }
        dt_on "${on_one%% *}" show
        say "Save the originals in ${STATE#"$ROOT"}/<time>/ first."
    fi
    case $on_live in
    "PMP off"*) say "Save m1n1/boot.bin, which has the PMP off, as m1n1/boot.bin.pre-pmp (for RECOVERY)." ;;
    esac
    say "Then rebuild Stage 2 with update-m1n1. The PMP starts at the next boot."
    if [ "$DRY_RUN" = 1 ]; then
        say
        say "Dry run: the changed tree checks out; nothing was written."
        return 0
    fi
    say
    say "EXPERIMENTAL: nobody has started an M1 Max with the PMP on yet. If Linux doesn't start"
    say "afterwards: update-m1n1 either installs the new Stage 2 as a one-time trial, which falls"
    say "back by itself (or hold the power button until the Mac turns off, then start it again), or"
    say "it replaces Stage 2, and you copy m1n1/boot.bin.pre-pmp back over m1n1/boot.bin from macOS"
    say "or recoveryOS. pmp.sh says which one happened; RECOVERY at the top of pmp.sh has the steps."
    confirm
    # shellcheck disable=SC2086
    need_writable $CHANGE "$STATE"

    BACKUP=
    if [ -n "$CHANGE" ]; then
        step "Saving the originals"
        BACKUP=$STATE/$(date -u +%Y%m%dT%H%M%SZ)
        mkdir -p "$BACKUP"
        chmod 700 "$STATE"
        i=0
        for on_f in $CHANGE; do
            i=$((i + 1))
            cp -p "$on_f" "$BACKUP/orig-$i.dtb"
            [ "$(sha "$BACKUP/orig-$i.dtb")" = "$(sha "$on_f")" ] || die "copying $on_f failed"
            printf '%s %s %s %s\n' "orig-$i.dtb" "$(sha "$on_f")" "$(sha "$TMP/new-$i.dtb")" \
                "${on_f#"$ROOT"}" >>"$BACKUP/manifest"
            note "${on_f#"$ROOT"} -> ${BACKUP#"$ROOT"}/orig-$i.dtb"
        done
    fi
    case $on_live in
    "PMP off"*)
        on_size=$(wc -c <"$ESP/m1n1/boot.bin" | tr -d ' ')
        on_free=$(df -Pk "$ESP" | awk 'NR == 2 { print $4 }')
        if [ -n "$ESP_MOUNTED" ]; then
            note "the EFI system partition is mounted read-only here; no boot.bin.pre-pmp (update-m1n1 keeps boot.bin.old)"
        elif [ "$on_free" -gt $(((on_size * 2 + 33554432) / 1024)) ]; then
            cp "$ESP/m1n1/boot.bin" "$ESP/m1n1/.boot.bin.pre-pmp.tmp"
            sync
            mv -f "$ESP/m1n1/.boot.bin.pre-pmp.tmp" "$ESP/m1n1/boot.bin.pre-pmp"
            sync
            note "m1n1/boot.bin -> m1n1/boot.bin.pre-pmp"
        else
            note "too little room on the EFI system partition for boot.bin.pre-pmp (update-m1n1 keeps boot.bin.old)"
        fi
        ;;
    esac

    if [ -n "$CHANGE" ]; then
        step "Changing the device tree"
        i=0
        for on_f in $CHANGE; do
            i=$((i + 1))
            install_file "$on_f" "$TMP/new-$i.dtb"
            note "${on_f#"$ROOT"}: PMP on"
        done
        sync
    fi

    on_rc=0
    run_update_m1n1 || on_rc=$?
    MODE=
    if esp_open; then
        if trial_armed && payload_has "$ESP/m1n1/boot.bin.next" "$WANT"; then
            MODE=trial
        elif payload_has "$ESP/m1n1/boot.bin" "$WANT"; then
            MODE=direct
        fi
    fi
    if [ -z "$MODE" ]; then
        if [ -z "$UPDATER" ]; then
            say
            say "Test root: Stage 2 wasn't rebuilt or checked."
            return 0
        fi
        step "Stage 2 doesn't carry the change (update-m1n1 exit $on_rc); undoing"
        [ -z "$BACKUP" ] || restore_backup "$BACKUP"
        run_update_m1n1 || true
        die "Stage 2 didn't take the changed device tree, so pmp.sh put the original back. If update-m1n1 said that this Stage 2 was attempted before, it fell back once already; 'sh pmp.sh status' shows the state."
    fi
    on_payload=$ESP/m1n1/boot.bin
    [ "$MODE" = direct ] || on_payload=$ESP/m1n1/boot.bin.next
    on_pv=$(aura_version_in "$on_payload" || true)
    aura_at_least "$on_pv" "$MIN_AURA" || say "warning: the new Stage 2's aura is ${on_pv:-unknown}, older than $MIN_AURA"
    say
    say "Done: the PMP starts at the next boot (Stage 2 aura $on_pv). Reboot when ready: systemctl reboot"
    say "Then 'sh pmp.sh status' should show the PMP driver bound."
    say "A kernel update turns the PMP off again; run 'sudo sh pmp.sh on' again after each one."
    say
    if [ "$MODE" = trial ]; then
        say "RECOVERY: the new Stage 2 is a one-time trial (m1n1/boot.bin.next); the working one stays."
        say "If Linux doesn't come up, the Mac restarts by itself (aura's watchdog, or after about"
        say "12 minutes); you can also hold the power button until it turns off, then start it again."
        say "It then starts the previous Stage 2, without the PMP. Then run: sudo sh pmp.sh off"
    else
        say "RECOVERY: the new Stage 2 replaced m1n1/boot.bin. If Linux doesn't come up, hold the power"
        say "button at startup, start macOS (or recoveryOS: Options > Utilities > Terminal), and copy"
        say "m1n1/boot.bin.pre-pmp (or boot.bin.old) over m1n1/boot.bin on the Aurora EFI partition"
        say "(PARTUUID $(chosen asahi,efi-system-partition)). The steps are at the top of pmp.sh."
        say "Then start Aurora and run: sudo sh pmp.sh off"
    fi
}

cmd_off() {
    common_checks
    step "Checking"
    CHANGE='' i=0
    for off_k in $(kernels); do
        for off_f in $(kernel_dtbs "$off_k"); do
            off_s=$(dt_state "$off_f") || die "${off_f#"$ROOT"} isn't as expected: $off_s. Nothing was changed"
            note "${off_f#"$ROOT"}: PMP $off_s"
            [ "$off_s" = on ] || continue
            i=$((i + 1))
            if off_o=$(find_original "$off_f"); then
                cp "$off_o" "$TMP/old-$i.dtb"
                note "  put back the original saved in ${off_o#"$ROOT"}"
            else
                cp "$off_f" "$TMP/old-$i.dtb"
                dt_off "$TMP/old-$i.dtb"
                note "  no saved original matches it: undo the changes with fdtput"
            fi
            off_t=$(dt_state "$TMP/old-$i.dtb") || true
            [ "$off_t" = off ] || die "the restored tree doesn't check out ($off_t); nothing was changed"
            CHANGE="$CHANGE $off_f"
        done
    done
    off_live=$(describe_payload "$ESP/m1n1/boot.bin")
    note "m1n1/boot.bin: $off_live"
    if [ -z "$CHANGE" ]; then
        case $off_live in
        "PMP on"*) ;;
        *)
            if [ -f "$ESP/m1n1/boot.bin.pre-pmp" ] && [ "$DRY_RUN" != 1 ] && [ -z "$ESP_MOUNTED" ]; then
                rm -f "$ESP/m1n1/boot.bin.pre-pmp"
                note "removed m1n1/boot.bin.pre-pmp, which isn't needed any more"
            fi
            say
            say "The PMP is off already, in the device trees and in Stage 2."
            return 0
            ;;
        esac
    fi
    step "Plan"
    if [ -n "$CHANGE" ]; then
        say "Put back the original device tree in:"
        for off_f in $CHANGE; do note "${off_f#"$ROOT"}"; done
    fi
    say "Then rebuild Stage 2 with update-m1n1. The PMP stays off from the next boot."
    if [ "$DRY_RUN" = 1 ]; then
        say
        say "Dry run: nothing was written."
        return 0
    fi
    confirm
    # shellcheck disable=SC2086
    need_writable $CHANGE
    BACKUP=$STATE
    if [ -n "$CHANGE" ]; then
        step "Changing the device tree"
        i=0
        for off_f in $CHANGE; do
            i=$((i + 1))
            install_file "$off_f" "$TMP/old-$i.dtb"
            note "${off_f#"$ROOT"}: PMP off"
        done
        sync
    fi
    off_rc=0
    run_update_m1n1 || off_rc=$?
    if [ -n "$UPDATER" ]; then
        esp_open || die "can't read m1n1/boot.bin after update-m1n1 (exit $off_rc)"
        off_next=$ESP/m1n1/boot.bin
        ! trial_armed || off_next=$ESP/m1n1/boot.bin.next
        off_after=$(describe_payload "$off_next")
        note "${off_next#"$ESP/"} (next boot): $off_after"
        case $off_after in
        "PMP off"*) ;;
        *) die "update-m1n1 (exit $off_rc) didn't rebuild Stage 2 without the PMP; run 'sudo update-m1n1' and read its messages" ;;
        esac
        if [ -z "$ESP_MOUNTED" ] && ! trial_armed; then
            rm -f "$ESP/m1n1/boot.bin.pre-pmp"
        fi
    fi
    say
    say "Done: the PMP is off from the next boot. Reboot when ready: systemctl reboot"
}

main() {
    CMD='' DRY_RUN=0 YES=0
    for arg in "$@"; do
        case $arg in
        status | on | off)
            [ -z "$CMD" ] || die "one command at a time"
            CMD=$arg
            ;;
        --dry-run | -n) DRY_RUN=1 ;;
        -y | --yes) YES=1 ;;
        -h | --help)
            usage
            return 0
            ;;
        *)
            usage >&2
            exit 2
            ;;
        esac
    done
    trap 'esp_close; [ -z "$TMP" ] || rm -rf "$TMP"' EXIT
    trap 'exit 130' INT TERM
    case ${CMD:-status} in
    status) cmd_status ;;
    on) cmd_on ;;
    off) cmd_off ;;
    esac
}

main "$@"
