# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
# shellcheck disable=SC2034
libs_desc="Plzip is a massively parallel (multithreaded) implementation of lzip"
libs_lic='GPL-2.0-or-later'
libs_ver=1.12
libs_url=(
    https://download.savannah.gnu.org/releases/lzip/plzip/plzip-$libs_ver.tar.gz
)
libs_sha=50d71aad6fa154ad8c824279e86eade4bcf3bb4932d757d8f281ac09cfadae30
libs_dep=( lzlib )

libs_args=(
    CXX="'$CXX'"
    CXXFLAGS="'$CXXFLAGS'"
    CPPFLAGS="'$CPPFLAGS'"
    LDFLAGS="'$LDFLAGS'"
)

libs_build() {
    configure

    pkgfile plzip -- make install-bin

    check plzip --version

    caveats << EOF
static built plzip @ $libs_ver

Usage:
    tar -I plzip -xf archive.tar.lz -C /tmp
    tar -I plzip -cf archive.tar.lz -C /opt
EOF
}
