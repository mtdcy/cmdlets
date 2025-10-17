# shellcheck disable=SC2034

libs_name=lzo
libs_desc="Real-time data compression library"

libs_lic='GPL-2.0-or-later'
libs_ver=2.10
libs_url=https://www.oberhumer.com/opensource/lzo/download/lzo-$libs_ver.tar.gz
libs_sha=c0f892943208266f9b6543b3ae308fab6284c5c90e627931446fb49b4221a072
libs_dep=()

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --enable-silent-rules

    --enable-pic

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    configure && make && make check || return $?

    pkgfile liblzo2 -- make install install-data
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
