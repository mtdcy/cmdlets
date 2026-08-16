# C library for the Public Suffix List

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.23.2
libs_url=https://github.com/rockdaboot/libpsl/releases/download/0.23.2/libpsl-0.23.2.tar.gz
libs_sha=f2ea0e59bffb36597a872f6ef89893ffa4c30196c87eff7aeb2c47e4e8c98133
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
