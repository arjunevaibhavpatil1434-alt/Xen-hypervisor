#!/bin/bash
# uart-boot-capture.sh - record the board's UART with a timestamp on every line.
#
#   ./uart-boot-capture.sh [seconds] [device] > boot.log    capture (default 120 s, /dev/ttyUSB0)
#   ./uart-boot-capture.sh --rel boot.log                   print times relative to "U-Boot TPL"
#
# Start it, then reset or power on the board (or type "reboot" in dom0 from
# another terminal). Close picocom first: only one program can read the UART.
# Each output line is "<epoch seconds> <UART text>". Xen, dom0 and the guests
# share the one UART, so some lines come out interleaved or cut.
set -u
if [ "${1:-}" = --rel ]; then
    LC_ALL=C awk '/U-Boot TPL/ && !t0 {t0=$1} t0 {printf "%7.2f %s\n", $1-t0, substr($0, index($0," ")+1)}' "$2"
    exit
fi
secs=${1:-120}; dev=${2:-/dev/ttyUSB0}
stty -F "$dev" 115200 cs8 -cstopb -parenb raw -echo -crtscts || exit 1
end=$((SECONDS + secs))
while [ $SECONDS -lt $end ]; do
    if IFS= read -r -t 1 line; then
        printf "%s %s\n" "$EPOCHREALTIME" "${line%$'\r'}"
    fi
done < "$dev"
