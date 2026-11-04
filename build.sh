#!/usr/bin/env bash
# build.sh - build the Tinker Board RK3288 Yocto + Xen image.
#
#   ./build.sh                      build tinker-xen-test-image
#   ./build.sh <target>             build another bitbake target
#   ./build.sh --sync [target]      run ./sync.sh first
#   ./build.sh --clean [target]     cleansstate the target first
#
# Environment (all optional, useful on a CI/test machine):
#   IMAGE_TARGET   default target (tinker-xen-test-image)
#   BUILD_DIR      build directory (default ./build)
#   DL_DIR         shared download cache
#   SSTATE_DIR     shared sstate cache
#   TINKER_SSH_KEY public key file(s) baked into the image for root SSH
#   BB_NUMBER_THREADS / PARALLEL_MAKE   override parallelism
#
# Exit code is bitbake's.  The last log is in $BUILD_DIR/logs/.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BUILD_DIR="${BUILD_DIR:-$PROJECT_DIR/build}"
IMAGE_TARGET="${IMAGE_TARGET:-tinker-xen-test-image}"
EXPECTED_MACHINE="tinker-board"

DO_SYNC=0
DO_CLEAN=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --sync)  DO_SYNC=1 ;;
        --clean) DO_CLEAN=1 ;;
        -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
        -*) echo "Unknown option: $1" >&2; exit 2 ;;
        *)  IMAGE_TARGET="$1" ;;
    esac
    shift
done

echo "=== Tinker Board RK3288: Yocto + Xen"
echo "Project: $PROJECT_DIR"
echo "Build:   $BUILD_DIR"
echo "Target:  $IMAGE_TARGET"

if (( DO_SYNC )) || [[ ! -f "$PROJECT_DIR/poky/oe-init-build-env" ]] \
                 || [[ ! -f "$BUILD_DIR/conf/local.conf" ]]; then
    "$PROJECT_DIR/sync.sh"
fi

"$PROJECT_DIR/sync.sh" --check || {
    echo "ERROR: layers are not on the commits pinned in sync.sh; run ./build.sh --sync" >&2
    exit 1
}

# Pass cache/key settings from the environment through to bitbake.
export BB_ENV_PASSTHROUGH_ADDITIONS="${BB_ENV_PASSTHROUGH_ADDITIONS:-} DL_DIR SSTATE_DIR TINKER_SSH_KEY BB_NUMBER_THREADS PARALLEL_MAKE"

set +u
# shellcheck disable=SC1091
source "$PROJECT_DIR/poky/oe-init-build-env" "$BUILD_DIR" >/dev/null
set -u

MACHINE_VALUE="$(bitbake -e "$IMAGE_TARGET" | sed -n 's/^MACHINE="\(.*\)"$/\1/p' | head -n 1)"
echo "Machine: $MACHINE_VALUE"
if [[ "$MACHINE_VALUE" != "$EXPECTED_MACHINE" ]]; then
    echo "ERROR: expected MACHINE=$EXPECTED_MACHINE. Stopping." >&2
    exit 1
fi

mkdir -p "$BUILD_DIR/logs"
LOG="$BUILD_DIR/logs/build-$IMAGE_TARGET-$(date +%Y%m%d-%H%M%S).log"
echo "Log:     $LOG"

if (( DO_CLEAN )); then
    bitbake -c cleansstate "$IMAGE_TARGET" 2>&1 | tee -a "$LOG"
fi

start=$(date +%s)
set +e
bitbake "$IMAGE_TARGET" 2>&1 | tee -a "$LOG"
rc=${PIPESTATUS[0]}
set -e
echo "Build time: $(( ($(date +%s) - start) / 60 )) min, exit code $rc" | tee -a "$LOG"
[[ $rc -eq 0 ]] || { echo "BUILD FAILED, see $LOG" >&2; exit "$rc"; }

DEPLOY_DIR="$BUILD_DIR/tmp/deploy/images/$MACHINE_VALUE"
WIC="$DEPLOY_DIR/$IMAGE_TARGET-$MACHINE_VALUE.wic"
echo "=== Artifacts in $DEPLOY_DIR"
find "$DEPLOY_DIR" -maxdepth 1 \
    \( -name '*.wic' -o -name '*.wic.bmap' -o -name '*.dtb' -o -name 'xen*' \
       -o -name 'zImage*' -o -name 'u-boot*' -o -name 'idbloader*' \) -print | sort
if [[ -e "$WIC" ]]; then
    ( cd "$DEPLOY_DIR" && sha256sum "$(readlink -f "$WIC" | xargs basename)" ) | tee -a "$LOG"
    echo "Flash with: ./flash.sh /dev/sdX"
fi
