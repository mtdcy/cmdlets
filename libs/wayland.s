# Protocol for a compositor to talk to its clients

libs_targets=(linux)

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.26.0
libs_rev=2
libs_url=(
    https://github.com/sailfishos-mirror/wayland/archive/refs/tags/$libs_ver.tar.gz
    #https://gitlab.freedesktop.org/wayland/wayland/-/releases/$libs_ver/downloads/wayland-$libs_ver.tar.gz
)
libs_sha=56b3a985cbfe17a926e3bcf037e4d374f44eaa33f3a4b364549dddf0d324cebc
libs_dep=(expat libffi libxml2)

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

    cmdlet.pkgfile libwayland -- meson.install --tags devel

    cmdlet.install src/wayland-scanner

    cmdlet.check wayland-scanner
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
