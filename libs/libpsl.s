# C library for the Public Suffix List

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.23.0
libs_url=https://github.com/rockdaboot/libpsl/releases/download/0.23.0/libpsl-0.23.0.tar.gz
libs_sha=f39b9631b3d369a21259ea4654f8875c0ec6995ce9551c0eb5d423e4c011f911
libs_dep=( libidn2 libunistring )

# configure args
libs_args=(
    -Druntime=libidn2
    -Dbuiltin=true
)

libs_build() {

    meson.setup

    meson.compile

    pkgfile libpsl -- meson.install --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
