SUMMARY = "media1: attach dom0's camera and sound codec (USB/IP)"
DESCRIPTION = "usb-attach attaches every USB device dom0's usb-share exports \
(the rear camera and the onboard sound codec) over xenbr0 with USB/IP, and \
again after a reconnect. The kernel then sees them as local USB devices \
(uvcvideo: /dev/video0, snd-usb-audio: ALSA card Audio)."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://usb-attach.init"
S = "${WORKDIR}"

inherit update-rc.d allarch

INITSCRIPT_NAME = "usb-attach"
# after networking (40), before audio-mixer and rear-camera (80, 81)
INITSCRIPT_PARAMS = "start 79 2 3 4 5 . stop 21 0 1 6 ."

do_install() {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${S}/usb-attach.init ${D}${sysconfdir}/init.d/usb-attach
}

RDEPENDS:${PN} = "usbip-tools kernel-module-vhci-hcd kernel-module-uvcvideo \
    kernel-module-snd-usb-audio"
