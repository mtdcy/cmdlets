# C library for the Public Suffix List

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.23.1
libs_url=https://github.com/rockdaboot/libpsl/releases/download/0.23.1/libpsl-0.23.1.tar.gz
libs_sha=8fbb03054556498ba9c4cc48fcaa36a4483748c6504a65bdb9ba348f555b0e56
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
