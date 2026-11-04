SUMMARY = "Tinker Board RK3288 Xen bring-up test image (experimental)"
DESCRIPTION = "core-image-minimal plus the debug Xen hypervisor copied to the \
FAT boot partition as /xen. U-Boot runs /boot.scr at power-on, which starts \
Xen; /native/extlinux.conf boots Linux without Xen."

require recipes-core/images/core-image-minimal.bb

# No generated /extlinux/extlinux.conf, so U-Boot's distro boot uses /boot.scr
WKS_FILE = "tinker-xen.wks"

# Copy the deployed Xen binary (renamed to /xen), its U-Boot script (as
# /boot.scr for power-on and /xen-boot.scr for the prompt) and the
# Linux-without-Xen entry into the boot partition
IMAGE_BOOT_FILES:append = " xen-${MACHINE};xen xen-boot.scr xen-boot.scr;boot.scr \
    native-extlinux.conf;native/extlinux.conf"

# Xen is not a sysroot dependency of the image, so wait for its deploy step
do_image_wic[depends] += "xen:do_deploy xen-boot-script:do_deploy \
    media-guest-image:do_image_complete"

# Xen toolstack (xl, xenstored, xenconsoled, xencommons init script), the dom0
# backend modules it loads, guest networking with NAT (vif-bridge scripts +
# bridge xenbr0) and a FreeRTOS guest; the guests start at boot
# start at boot (xen-guests) and a hung system is reset by the hardware
# watchdog (xen-guests-watchdog).
# media1 (media-guest): a Yocto Linux guest that plays videos and pictures
# (ffmpeg lives there, not in dom0); its root filesystem is a partition of
# its own (tinker-xen.wks), the kernel is dom0's /boot/zImage.
# Screens, touch and sound: QEMU (Xen's device model) serves the guests' PV
# framebuffers and touch over local VNC; display-map shows each OS on a
# screen of its own (HDMI with the Rockchip DRM modules, USB display
# adapters with udl): guest VNC displays through the framebuffer viewer with dom0's
# touchscreen/mouse/keyboard, the instrument cluster and dom0's console.
# Rear camera and sound belong to media1: usb-share exports the USB webcam
# and the onboard USB audio codec to it with USB/IP (the RK3288's USB
# controllers have no IOMMU, so Xen cannot pass them through), media-link
# sends it the gear frames (CAN) and chime requests (FreeRTOS warnings).
# Automotive bench (vehicle-bench): CAN (virtual bus, USB adapters,
# can-utils), a simulated vehicle, the read-only CAN -> FreeRTOS gateway and
# an instrument-cluster dashboard (cluster-hdmi); ignition-watch for a
# clean power-off when the car's ACC goes off (disabled until wired).
# xen-consoles: dom0 and guest consoles side by side (tmux) on the one
# serial line.
IMAGE_INSTALL:append = " \
    xen-tools-xencommons \
    kernel-module-xen-gntdev kernel-module-xen-gntalloc \
    kernel-module-xen-blkback kernel-module-xen-netback kernel-module-xen-wdt \
    xen-tools-scripts-network xen-tools-scripts-block xenbr0 \
    freertos-xen-guest \
    media-guest \
    xen-guests xen-guests-watchdog \
    qemu guest-vnc display-map \
    kernel-module-rockchipdrm kernel-module-dw-hdmi kernel-module-vfb kernel-module-udl \
    usb-share media-link \
    vehicle-bench can-utils cluster-hdmi ignition-watch \
    xen-consoles \
    kernel-module-vcan kernel-module-gs-usb kernel-module-peak-usb kernel-module-slcan \
    "

# SSH into dom0 (dropbear) over eth0, key logins only (TINKER_SSH_KEY)
inherit tinker-ssh

# No login prompts: every console logs root in by itself
inherit tinker-autologin

# Free space on dom0's root filesystem (32 MB): the guest kernels and
# ramdisk are already in the image, and /var/log is in RAM
IMAGE_ROOTFS_EXTRA_SPACE = "32768"
