# Library for accessing the direct rendering manager

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.4.128
libs_url=https://dri.freedesktop.org/libdrm/libdrm-$libs_ver.tar.xz
libs_sha=3bb35db8700c2a0b569f2c6729a53f5495786856b310854c8de57782a22bddac

libs_args=(
    -Dudev=false
    -Dcairo-tests=disabled
    -Dvalgrind=disabled
)

libs_build() {
    depends_on is_linux

    mkdir -p build

    meson setup build && 

    meson compile -C build --verbose &&

    pkgfile libdrm -- meson install -C build --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
