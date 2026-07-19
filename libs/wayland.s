# Protocol for a compositor to talk to its clients

libs_targets=( linux )

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.26.0
libs_url=https://gitlab.freedesktop.org/wayland/wayland/-/releases/$libs_ver/downloads/wayland-$libs_ver.tar.xz
libs_sha=64176eaa46e4969903e286f8e5ef8331affc17fdf03ac9b58381d2b23162b7a3
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

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
