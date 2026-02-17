# Pluggable Authentication Modules for Linux

libs_targets=( linux )

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.7.2
libs_url=https://github.com/linux-pam/linux-pam/releases/download/v1.7.2/Linux-PAM-1.7.2.tar.xz
libs_sha=3d86b6383fb5fd9eb9578d2cd47d92801191f4bf3f9bc61419bfefc8aa1e531a
libs_dep=( libnsl libtirpc libxcrypt )

# configure args
libs_args=(
    --sysconfdir==/etc/

    -Di18n=disabled
    -Ddocs=disabled
    #-Dexamples=False

    # no modules
    -Dpam_unix=disabled
    -Dpam_userdb=disabled
)

libs_build() {

    if test -d /lib/security; then
        libs_args+=( -Dsecuredir=/lib/security )
    else
        libs_args+=( -Dsecuredir=/lib/$(uname -m)-linux-gnu/security )
    fi

    sed -i meson.build \
        -e '/modules/d'

    sed -i libpam/meson.build libpamc/meson.build libpam_misc/meson.build \
        -e 's/shared_library/static_library/' \
        -e '/version:/d' \
        -e '/link_depends:/d' \
        -e '/link_args:/d'

    sed -i libpam_internal/meson.build \
        -e '/dependencies:/a install: true,'

    meson setup build

    meson compile -C build --verbose

    pkgfile libpam -- meson install -C build
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
