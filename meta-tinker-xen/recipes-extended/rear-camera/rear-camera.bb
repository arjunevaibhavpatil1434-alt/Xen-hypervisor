SUMMARY = "Rear-view camera on media1's screen while the car is in reverse"
DESCRIPTION = "rear-camera runs in the media1 guest, which owns the USB \
camera (dom0 gives it with USB/IP). dom0's media-link sends it the gear \
frames from the vehicle CAN bus. In reverse it pauses media1's video player \
(media-ctl), shows the camera mirrored with parking guide lines on media1's \
screen (which dom0 shows on HDMI) and plays the reverse chime; one second \
after reverse the camera is closed and the video carries on."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://rear-camera.c file://rear-camera.init file://rear-camera.default"
S = "${WORKDIR}"

inherit update-rc.d

INITSCRIPT_NAME = "rear-camera"
# after audio-mixer (80), before media-player (94)
INITSCRIPT_PARAMS = "start 81 2 3 4 5 . stop 19 0 1 6 ."

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -Wall -Wextra -o rear-camera ${S}/rear-camera.c
}

do_install() {
    install -d ${D}${bindir} ${D}${sysconfdir}/init.d ${D}${sysconfdir}/default
    install -m 0755 ${B}/rear-camera ${D}${bindir}/rear-camera
    install -m 0755 ${S}/rear-camera.init ${D}${sysconfdir}/init.d/rear-camera
    install -m 0644 ${S}/rear-camera.default ${D}${sysconfdir}/default/rear-camera
}

CONFFILES:${PN} = "${sysconfdir}/default/rear-camera"
RDEPENDS:${PN} = "kernel-module-uvcvideo"
