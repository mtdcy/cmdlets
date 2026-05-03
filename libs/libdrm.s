# Library for accessing the direct rendering manager

libs_targets=( linux )

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.4.132
libs_url=https://dri.freedesktop.org/libdrm/libdrm-$libs_ver.tar.xz
libs_sha=df9091045e1115d4ff3eb01dbb6514168f0fe91e6f3e820dd5b21da040721eda

libs_args=(
    -Dudev=false
    -Dcairo-tests=disabled
    -Dvalgrind=disabled
)

libs_build() {

    meson.setup

    meson.compile

    pkgfile libdrm -- meson.install --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
