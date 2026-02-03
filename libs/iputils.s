# Set of small useful utilities for Linux networking
#
# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=20250605
libs_url=https://github.com/iputils/iputils/archive/refs/tags/20250605.tar.gz
libs_sha=19e680c9eef8c079da4da37040b5f5453763205b4edfb1e2c114de77908927e4
libs_dep=( libxslt libidn2 libcap )

# configure args
libs_args=(
    -DBUILD_TRACEPATH=true

    -DBUILD_PING=false   # prefer inetutils-ping
    -DBUILD_ARPING=false # prefer portable impl
    -DBUILD_MANS=false

    -DUSE_CAP=true
    -DUSE_IDN=true
    -DUSE_GETTEXT=false

    -DSKIP_TESTS=false
)

libs_build() {

    meson setup build

    meson compile -C build --verbose

    pkgfile libiputils -- meson install -C build

    #cmdlet ./build/ping/ping
    cmdlet ./build/tracepath

    check ping -V
}

libs_depends is_linux

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
