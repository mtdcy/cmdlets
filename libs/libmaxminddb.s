# C library for the MaxMind DB file format
#
# shellcheck disable=SC2034
libs_lic="Apache-2.0"
libs_ver=1.12.2
libs_url=https://github.com/maxmind/libmaxminddb/releases/download/$libs_ver/libmaxminddb-$libs_ver.tar.gz
libs_sha=1bfbf8efba3ed6462e04e225906ad5ce5fe958aa3d626a1235b2a2253d600743
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
