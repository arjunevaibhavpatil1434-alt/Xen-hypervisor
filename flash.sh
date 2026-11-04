#!/usr/bin/env bash
# flash.sh - erase an SD card and write the Tinker Board image to it.
#
#   ./flash.sh /dev/sdX                 write the latest tinker-xen-test-image
#   ./flash.sh /dev/sdX <image.wic>     write a specific .wic file
#   ./flash.sh -y /dev/sdX              no confirmation prompt (for scripts)
#   ./flash.sh --list                   show removable disks
#
# Safety: refuses anything that is not a removable, unmounted-by-the-system
# whole disk, or bigger than MAX_GB (default 128).  Needs sudo.
# BOARD_IP (default 192.168.88.110) is only used in the hints printed at the
# end: a freshly written card has a new SSH host key.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROJECT_DIR/build}"
IMAGE_TARGET="${IMAGE_TARGET:-tinker-xen-test-image}"
MACHINE="tinker-board"
MAX_GB="${MAX_GB:-128}"
BOARD_IP="${BOARD_IP:-192.168.88.110}"

YES=0
DEV=""
IMG=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes) YES=1 ;;
        --list) lsblk -d -o NAME,SIZE,RM,TRAN,MODEL | awk 'NR==1 || $3==1'; exit 0 ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        /dev/*) DEV="$1" ;;
        *) IMG="$1" ;;
    esac
    shift
done

[[ -n "$DEV" ]] || { echo "Usage: $0 [-y] /dev/sdX [image.wic]   (see --list)" >&2; exit 2; }
IMG="${IMG:-$BUILD_DIR/tmp/deploy/images/$MACHINE/$IMAGE_TARGET-$MACHINE.wic}"
IMG="$(readlink -f "$IMG")"
[[ -f "$IMG" ]] || { echo "ERROR: image not found: $IMG (run ./build.sh first)" >&2; exit 1; }

# --- device checks ---------------------------------------------------------
[[ -b "$DEV" ]] || { echo "ERROR: $DEV is not a block device (card not inserted?)" >&2; exit 1; }
[[ "$(lsblk -dno TYPE "$DEV")" == "disk" ]] || { echo "ERROR: $DEV is a partition; give the whole disk, e.g. /dev/sda" >&2; exit 1; }
[[ "$(lsblk -dno RM "$DEV" | tr -d ' ')" == "1" ]] || { echo "ERROR: $DEV is not removable, refusing" >&2; exit 1; }
size_gb=$(( $(lsblk -dbno SIZE "$DEV") / 1000000000 ))
(( size_gb > 0 && size_gb <= MAX_GB )) || { echo "ERROR: $DEV is ${size_gb} GB (limit ${MAX_GB} GB), refusing" >&2; exit 1; }
if lsblk -no MOUNTPOINT "$DEV" | grep -qE '^(/|/boot.*|/home|/usr|/var)$'; then
    echo "ERROR: $DEV holds a system mount, refusing" >&2; exit 1
fi

BMAP="${IMG}.bmap"

echo "=== Flash Tinker Board SD card"
echo "Image:  $IMG"
echo "        $(du -h "$IMG" | cut -f1), built $(date -r "$IMG" '+%F %T')"
if [[ -f "$BMAP" ]]; then
    blocks=$(sed -n 's:.*<MappedBlocksCount> *\([0-9]*\).*:\1:p' "$BMAP")
    bsize=$(sed -n 's:.*<BlockSize> *\([0-9]*\).*:\1:p' "$BMAP")
    [[ -n "$blocks" && -n "$bsize" ]] && \
        awk -v n="$blocks" -v b="$bsize" 'BEGIN{printf "        %.1f MB of it is data (only that is written with bmaptool)\n", n*b/1048576}'
fi
echo "Device: $DEV"
lsblk -o NAME,SIZE,RM,TRAN,MODEL,MOUNTPOINT "$DEV"

if (( ! YES )); then
    read -r -p "ERASE everything on $DEV and write the image? Type yes: " ans
    [[ "$ans" == "yes" ]] || { echo "Aborted."; exit 1; }
fi

# --- erase + write -----------------------------------------------------------
for p in $(lsblk -lnpo NAME "$DEV" | tail -n +2); do
    sudo umount "$p" 2>/dev/null || true
done
echo "=== Erasing old partition table and signatures"
# shellcheck disable=SC2046
sudo wipefs -a $(lsblk -lnpo NAME "$DEV" | tail -n +2) "$DEV"

echo "=== Writing image"
if command -v bmaptool >/dev/null && [[ -f "$BMAP" ]]; then
    sudo bmaptool copy --bmap "$BMAP" "$IMG" "$DEV"
else
    echo "(bmaptool or .bmap missing, using dd: slower)"
    sudo dd if="$IMG" of="$DEV" bs=4M conv=fsync status=progress
fi
sync
sudo partprobe "$DEV" 2>/dev/null || true
sleep 1
lsblk -o NAME,SIZE,TYPE,FSTYPE "$DEV"
echo "DONE: $DEV is ready. Eject it and boot the Tinker Board."
cat <<EOF

First boot (times after power-on):
  ~38 s  rtos1 (FreeRTOS) draws its dashboard on the SPI TFT
  ~43 s  dom0 logs in by itself on the serial console
  ~55 s  media1 plays its video on HDMI; up to ~65 s if xen-guests has to
         restart it (common after power-on, see /var/log/xen-guests.log)
The card has a new SSH host key. Remove the old one first:
  ssh-keygen -R $BOARD_IP
EOF
