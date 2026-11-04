#!/usr/bin/env bash
# sync.sh - fetch the upstream Yocto layers at pinned commits, then create
# build/conf (local.conf + bblayers.conf) if it is missing.
#
#   ./sync.sh            clone missing layers, check out the pinned commits
#   ./sync.sh --force    also throw away local changes inside the layers
#   ./sync.sh --check    only report whether every layer is on its pin
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROJECT_DIR/build}"

# Upstream layers:  <dir>  <git url>  <branch>  <pinned commit>
# To move a layer forward: change the commit here, sync, build, test on the
# board, then push the change for review.
LAYERS="
poky                https://git.yoctoproject.org/poky.git               kirkstone  445a6223929b9a7a62b575093659e3d9e1aba982
meta-arm            https://git.yoctoproject.org/meta-arm.git           kirkstone  c3e9fb12aa31d25e33d8392c4a233ed1275a3278
meta-openembedded   https://git.openembedded.org/meta-openembedded.git  kirkstone  ce8539c941f6fcbecaca4d16640ac105c0595589
meta-rockchip       https://git.yoctoproject.org/meta-rockchip.git      kirkstone  1e27f83cc4105739ff354d92bce82c20fae77da1
meta-virtualization https://git.yoctoproject.org/meta-virtualization    kirkstone  92b6abcdfb6f12c4931247f0f29aaf5331984525
"

FORCE=0
CHECK=0
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        --check) CHECK=1 ;;
        -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

bad=0
while read -r dir url branch commit; do
    [[ -z "$dir" ]] && continue
    path="$PROJECT_DIR/$dir"

    if (( CHECK )); then
        have="$(git -C "$path" rev-parse HEAD 2>/dev/null || echo missing)"
        if [[ "$have" == "$commit" ]]; then
            printf 'OK      %-20s %s\n' "$dir" "$commit"
        else
            printf 'WRONG   %-20s have %s, want %s\n' "$dir" "$have" "$commit"
            bad=1
        fi
        continue
    fi

    echo "=== $dir ($branch @ ${commit:0:12})"
    if [[ ! -d "$path/.git" ]]; then
        git clone --branch "$branch" "$url" "$path"
    elif ! git -C "$path" cat-file -e "$commit^{commit}" 2>/dev/null; then
        git -C "$path" fetch origin "$branch"
    fi

    if [[ -n "$(git -C "$path" status --porcelain --untracked-files=no)" ]]; then
        if (( FORCE )); then
            echo "    discarding local changes in $dir"
            git -C "$path" reset --hard -q
        else
            echo "ERROR: $dir has local changes. Put them in meta-tinker-xen" >&2
            echo "       (as a bbappend or patch), or rerun with --force." >&2
            exit 1
        fi
    fi
    git -C "$path" -c advice.detachedHead=false checkout -q "$commit"
done <<< "$LAYERS"

if (( CHECK )); then
    exit "$bad"
fi

# --- build/conf ---------------------------------------------------------------
CONF="$BUILD_DIR/conf"
if [[ -f "$CONF/local.conf" ]]; then
    echo "=== $CONF already exists, left unchanged"
    echo "Sync done."
    exit 0
fi

echo "=== Creating $CONF"
mkdir -p "$CONF"

cat > "$CONF/bblayers.conf" <<BBLAYERS
# Created by sync.sh
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "\${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \\
  $PROJECT_DIR/poky/meta \\
  $PROJECT_DIR/poky/meta-poky \\
  $PROJECT_DIR/poky/meta-yocto-bsp \\
  $PROJECT_DIR/meta-openembedded/meta-oe \\
  $PROJECT_DIR/meta-arm/meta-arm-toolchain \\
  $PROJECT_DIR/meta-arm/meta-arm \\
  $PROJECT_DIR/meta-rockchip \\
  $PROJECT_DIR/meta-openembedded/meta-filesystems \\
  $PROJECT_DIR/meta-openembedded/meta-python \\
  $PROJECT_DIR/meta-openembedded/meta-networking \\
  $PROJECT_DIR/meta-virtualization \\
  $PROJECT_DIR/meta-tinker-xen \\
  "
BBLAYERS

cat > "$CONF/local.conf" <<'LOCALCONF'
# Created by sync.sh. Local tweaks go here; change sync.sh (and push it for
# review) for anything every build needs.

MACHINE ?= "tinker-board"
DISTRO ?= "poky"
DISTRO_FEATURES:append = " virtualization xen"
PACKAGE_CLASSES ?= "package_rpm"
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"
LICENSE_FLAGS_ACCEPTED += "commercial"

# Public key(s) put in root's authorized_keys on dom0 and media1.
# build.sh passes TINKER_SSH_KEY through from the environment.
TINKER_SSH_KEY ?= "${@os.path.expanduser('~/.ssh/id_ed25519.pub') if os.path.exists(os.path.expanduser('~/.ssh/id_ed25519.pub')) else ''}"

# Shared caches: export DL_DIR / SSTATE_DIR before ./build.sh to share them
# between checkouts (default: inside the build directory).

BB_DISKMON_DIRS ??= "\
    STOPTASKS,${TMPDIR},1G,100K \
    STOPTASKS,${DL_DIR},1G,100K \
    STOPTASKS,${SSTATE_DIR},1G,100K \
    STOPTASKS,/tmp,100M,100K \
    HALT,${TMPDIR},100M,1K \
    HALT,${DL_DIR},100M,1K \
    HALT,${SSTATE_DIR},100M,1K \
    HALT,/tmp,10M,1K"

PACKAGECONFIG:append:pn-qemu-system-native = " sdl"
CONF_VERSION = "2"
LOCALCONF

echo "Sync done."
