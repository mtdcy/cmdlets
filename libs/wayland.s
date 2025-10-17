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
    depends_on is_linux

    mkdir -p build
    
    meson setup build && 

    meson compile -C build --verbose &&

    pkgfile libwayland -- meson install -C build --tags devel &&

    cmdlet ./build/src/wayland-scanner &&

    check wayland-scanner
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
