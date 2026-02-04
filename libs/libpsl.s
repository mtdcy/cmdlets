# C library for the Public Suffix List

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.21.5
libs_url=https://github.com/rockdaboot/libpsl/releases/download/0.21.5/libpsl-0.21.5.tar.gz
libs_sha=1dcc9ceae8b128f3c0b3f654decd0e1e891afc6ff81098f227ef260449dae208
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
