# EXIF and IPTC metadata manipulation library and tools
#  replacement for exiftool which is perl scripts

# shellcheck disable=SC2034
libs_lic="GPL-2.0-or-later"
libs_ver=0.28.7
libs_url=https://github.com/Exiv2/exiv2/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=5e292b02614dbc0cee40fe1116db2f42f63ef6b2ba430c77b614e17b8d61a638
libs_dep=( zlib expat brotli inih libiconv curl )

# configure args
libs_args=(
    -Dbrotli=enabled
    -Diconv=enabled
    -Dinih=enabled

    -Dbmff=true
    -Dpng=enabled
    -Dxmp=enabled

    -Dvideo=true
   
    # web ready
    -Dwebready=true
    -Dcurl=enabled

    -Dnls=disabled
    -DunitTests=disabled
)

libs_build() {
    mkdir -p build
    
    meson setup build && 

    meson compile -C build --verbose || return 1

    pkgfile libexiv2 -- meson install -C build --tags devel

    cmdlet ./build/exiv2 && 

    check exiv2 --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
