# No login prompts on the board's Linux images (dom0, media1): every console
# getty (hvc0 under Xen, ttyS2 without Xen, tty1) logs root in by itself.
# getty -n skips the user name question and -l runs /sbin/autologin instead
# of /bin/login; "login -f root" starts root's login shell without asking
# for a password. Logging out starts a new root shell. SSH stays key-only
# (tinker-ssh); single-user mode keeps sulogin for rescue.
ROOTFS_POSTPROCESS_COMMAND += "tinker_autologin;"
tinker_autologin() {
    al=${base_sbindir}/autologin
    printf '#!/bin/sh\nexec /bin/login -f root\n' > ${IMAGE_ROOTFS}$al
    chmod 0755 ${IMAGE_ROOTFS}$al

    # tty1: getty straight from inittab
    sed -i "s|:/sbin/getty |:/sbin/getty -n -l $al |" ${IMAGE_ROOTFS}${sysconfdir}/inittab
    # hvc0 (Xen console): getty-wrapper, which runs getty if the device exists
    sed -i "s|exec /sbin/getty |exec /sbin/getty -n -l $al |" ${IMAGE_ROOTFS}${base_sbindir}/getty-wrapper
    # ttyS2 (board UART without Xen): start_getty (sysvinit-inittab bbappend)
    # passes -n -l /sbin/autologin itself

    # fail the build if a console would still ask for a login
    if grep -E '^[^#]*:/sbin/getty ' ${IMAGE_ROOTFS}${sysconfdir}/inittab | grep -qv -- "-l $al "; then
        bbfatal "tinker-autologin: a getty in /etc/inittab still asks for a login"
    fi
    if grep -q 'exec /sbin/getty' ${IMAGE_ROOTFS}${base_sbindir}/getty-wrapper && \
       ! grep -q "exec /sbin/getty -n -l $al " ${IMAGE_ROOTFS}${base_sbindir}/getty-wrapper; then
        bbfatal "tinker-autologin: getty-wrapper (hvc0) still asks for a login"
    fi
    if [ -f ${IMAGE_ROOTFS}${base_bindir}/start_getty ] && \
       ! grep -q "autologin=\"-n -l $al\"" ${IMAGE_ROOTFS}${base_bindir}/start_getty; then
        bbfatal "tinker-autologin: start_getty (ttyS2) still asks for a login"
    fi
}
