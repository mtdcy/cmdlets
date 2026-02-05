# Protocol for a compositor to talk to its clients

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.24.0
libs_url=https://gitlab.freedesktop.org/wayland/wayland/-/releases/$libs_ver/downloads/wayland-$libs_ver.tar.xz
libs_sha=82892487a01ad67b334eca83b54317a7c86a03a89cfadacfef5211f11a5d0536
libs_dep=( expat libffi libxml2 )

# configure args
libs_args=(
    -Dlibraries=true
    -Dscanner=true

    -Dtests=false
    -Ddocumentation=false
)

libs_build() {

    meson.setup

    meson.compile

    pkgfile libwayland -- meson.install --tags devel

    cmdlet.install src/wayland-scanner

    cmdlet.check wayland-scanner
}

libs.depends is_linux

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
