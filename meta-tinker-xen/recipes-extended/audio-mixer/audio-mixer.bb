SUMMARY = "media1 audio pipeline: vehicle chimes and video sound to the speaker"
DESCRIPTION = "audio-mixer runs in the media1 guest, which owns the board's \
sound codec (a USB device dom0 gives it with USB/IP). It mixes the vehicle \
chimes (highest priority: the video sound is turned down while one plays; \
dom0's media-link sends the FreeRTOS warnings, rear-camera asks for the \
reverse chime) and media1's video sound into the speaker output with ALSA."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://audio-mixer.c file://audio-mixer.init file://audio-mixer.default"
S = "${WORKDIR}"

DEPENDS = "alsa-lib"

inherit update-rc.d

INITSCRIPT_NAME = "audio-mixer"
# after usb-attach (79), before rear-camera (81) and media-player (94)
INITSCRIPT_PARAMS = "start 80 2 3 4 5 . stop 20 0 1 6 ."

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -Wall -Wextra -o audio-mixer ${S}/audio-mixer.c -lasound -lm
}

do_install() {
    install -d ${D}${bindir} ${D}${sysconfdir}/init.d ${D}${sysconfdir}/default
    install -m 0755 ${B}/audio-mixer ${D}${bindir}/
    install -m 0755 ${S}/audio-mixer.init ${D}${sysconfdir}/init.d/audio-mixer
    install -m 0644 ${S}/audio-mixer.default ${D}${sysconfdir}/default/audio-mixer
}

CONFFILES:${PN} = "${sysconfdir}/default/audio-mixer"
RDEPENDS:${PN} = "kernel-module-snd-usb-audio"
