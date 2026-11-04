SUMMARY = "dom0 -> media1 link: gear frames and chime requests"
DESCRIPTION = "media1 owns the rear camera and the sound (USB devices it \
gets from dom0 with USB/IP, usb-share). media-link sends it the vehicle's \
gear frames from the CAN bus (receive only) and the chime requests made in \
dom0, over UDP on xenbr0. vehicle-chimes turns the FreeRTOS guest's \
real-time warnings into chime requests."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://media-link.c file://media-link.init file://media-link.default \
    file://vehicle-chimes"
S = "${WORKDIR}"

inherit update-rc.d

INITSCRIPT_NAME = "media-link"
# after xen-guests (90), before vehicle-bench (92)
INITSCRIPT_PARAMS = "start 91 2 3 4 5 . stop 09 0 1 6 ."

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -Wall -Wextra -o media-link ${S}/media-link.c
}

do_install() {
    install -d ${D}${bindir} ${D}${sysconfdir}/init.d ${D}${sysconfdir}/default
    install -m 0755 ${B}/media-link ${S}/vehicle-chimes ${D}${bindir}/
    install -m 0755 ${S}/media-link.init ${D}${sysconfdir}/init.d/media-link
    install -m 0644 ${S}/media-link.default ${D}${sysconfdir}/default/media-link
}

CONFFILES:${PN} = "${sysconfdir}/default/media-link"
