# C library for the MaxMind DB file format
#
# shellcheck disable=SC2034
libs_lic="Apache-2.0"
libs_ver=1.13.1
libs_url=https://github.com/maxmind/libmaxminddb/releases/download/$libs_ver/libmaxminddb-$libs_ver.tar.gz
libs_sha=49a2347f015683d83c5a281c1b2d38ca766a1f42d5183417973bf4ca9b8c4ca7
libs_dep=( )

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --with-pic

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    pkgfile "$libs_name" -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
