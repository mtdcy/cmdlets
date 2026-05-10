# Library for accessing the direct rendering manager

libs_targets=( linux )

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.4.133
libs_url=https://dri.freedesktop.org/libdrm/libdrm-$libs_ver.tar.xz
libs_sha=fc68f9d0ba2ea63c9432a299e14fea09fad7a8a66e8039fcd7802ca59f77b4f5

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
