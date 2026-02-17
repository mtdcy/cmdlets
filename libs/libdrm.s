# Library for accessing the direct rendering manager

libs_targets=( linux )

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.4.131
libs_url=https://dri.freedesktop.org/libdrm/libdrm-$libs_ver.tar.xz
libs_sha=45ba9983b51c896406a3d654de81d313b953b76e6391e2797073d543c5f617d5

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
