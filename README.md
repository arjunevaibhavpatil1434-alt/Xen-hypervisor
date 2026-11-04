# Xen Hypervisor — 3 Guests

## Tinker Board R2.0 (RK3288): Yocto + Xen Mixed-Criticality System

Xen 4.16 on an ASUS Tinker Board R2.0 running three operating systems at once:

- Yocto Linux 5.15 (dom0)
- A Linux media guest (media1) for audio/video playback
- FreeRTOS 11.1 on its own CPU core with the RTDS real-time scheduler

The project also includes an automotive CAN bench and an HDMI instrument-cluster dashboard.

## Project Documentation

- `docs/DOCUMENTATION.md` — All project documentation: Part 1 is a beginner's guide explaining the
  project step by step, Part 2 is the technical reference (code, addresses, checksums).
- `meta-tinker-xen/` — Yocto layer containing the project changes. See its README.
- `diagnostics/` — Engineering report (`REPORT.md`, sections A–Z), board test logs, and build logs.

## Build Environment

The build uses Yocto Kirkstone with Poky, meta-openembedded, meta-virtualization, meta-arm, and meta-rockchip. The exact layer commits are pinned in `sync.sh`.

## Build and Flash

```
./sync.sh              # fetch the upstream layers, create build/conf
./build.sh             # build tinker-xen-test-image (runs sync.sh if needed)
./flash.sh --list      # find the SD card
./flash.sh /dev/sdX    # erase the card and write the image
```

`build.sh` options: `--sync`, `--clean`, or another bitbake target. Set `DL_DIR` / `SSTATE_DIR`
to share download and sstate caches, and `TINKER_SSH_KEY` to choose the public key put on the board
(default `~/.ssh/id_ed25519.pub`). Each run saves a log in `build/logs/`.

More detail: `docs/DOCUMENTATION.md`, Part 1 Chapters 4 (setup) and 12 (build and flash).
