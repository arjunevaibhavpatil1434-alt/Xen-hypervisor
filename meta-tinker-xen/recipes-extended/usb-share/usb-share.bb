SUMMARY = "dom0: share the webcam and the sound codec with media1 (USB/IP)"
DESCRIPTION = "The RK3288 has no IOMMU for its USB controllers, so USB \
devices cannot be passed through to a guest with Xen. usb-share keeps the \
controllers in dom0 and exports the USB devices media1 needs (video and \
audio class: the rear camera and the onboard sound codec) with USB/IP; \
media1's usb-attach attaches them over xenbr0."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://usb-share.init file://usb-share.default"
S = "${WORKDIR}"

inherit update-rc.d allarch

INITSCRIPT_NAME = "usb-share"
# before xen-guests (90): the devices are ready when media1 starts
INITSCRIPT_PARAMS = "start 89 2 3 4 5 . stop 11 0 1 6 ."

do_install() {
    install -d ${D}${sysconfdir}/init.d ${D}${sysconfdir}/default
    install -m 0755 ${S}/usb-share.init ${D}${sysconfdir}/init.d/usb-share
    install -m 0644 ${S}/usb-share.default ${D}${sysconfdir}/default/usb-share
}

CONFFILES:${PN} = "${sysconfdir}/default/usb-share"
RDEPENDS:${PN} = "usbip-tools kernel-module-usbip-host"
