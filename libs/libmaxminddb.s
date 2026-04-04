# C library for the MaxMind DB file format
#
# shellcheck disable=SC2034
libs_lic="Apache-2.0"
libs_ver=1.13.0
libs_url=https://github.com/maxmind/libmaxminddb/releases/download/$libs_ver/libmaxminddb-$libs_ver.tar.gz
libs_sha=538b196e5885630c299fe1e49dd468db418e25407a0d04651ced51001ebf9766
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
