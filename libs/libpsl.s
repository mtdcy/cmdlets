# C library for the Public Suffix List

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.23.3
libs_url=https://github.com/rockdaboot/libpsl/releases/download/0.23.3/libpsl-0.23.3.tar.gz
libs_sha=93941f85a1e7bd593fa94f299233cb5dfc91cd144fd9a78a6ceb75001c5b03be
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
