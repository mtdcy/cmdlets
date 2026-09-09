# C library for the MaxMind DB file format
#
# shellcheck disable=SC2034
libs_lic="Apache-2.0"
libs_ver=1.14.0
libs_rev=1
libs_url=https://github.com/maxmind/libmaxminddb/releases/download/$libs_ver/libmaxminddb-$libs_ver.tar.gz
libs_sha=65ff92382c71ef6634b8c13e278651a2efa68f1de28ef3c31fc32369fa0bb3e3
libs_dep=()

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

    cmdlet.pkgfile "$libs_name" -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
