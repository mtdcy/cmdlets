# C library for creating IP packets

libs_targets=( linux darwin )

# shellcheck disable=SC2034
libs_lic='BSD-2-Clause'
libs_ver=1.3
libs_url=https://github.com/libnet/libnet/releases/download/v1.3/libnet-1.3.tar.gz
libs_sha=ad1e2dd9b500c58ee462acd839d0a0ea9a2b9248a1287840bc601e774fb6b28f
libs_dep=( )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-debug
    --disable-doxygen-doc

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    pkgfile $libs_name -- make install bin_SCRIPTS=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
