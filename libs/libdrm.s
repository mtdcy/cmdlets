# Library for accessing the direct rendering manager

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.4.127
libs_url=https://dri.freedesktop.org/libdrm/libdrm-$libs_ver.tar.xz
libs_sha=051aeb3e542a57621018ffc443fb088dd69b78eef0ce4808b604ce0feac9f47f

libs_args=(
    -Dudev=false
    -Dcairo-tests=disabled
    -Dvalgrind=disabled
)

libs_build() {
    is_darwin && {
        slogw "*****" "**** Not supported on $OSTYPE! ****"
        exit 0
    }

    mkdir -p build

    meson setup build && 

    meson compile -C build --verbose &&

    pkgfile libdrm -- meson install -C build --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
