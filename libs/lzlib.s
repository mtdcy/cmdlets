# shellcheck disable=SC2034

libs_desc="Data compression library"
libs_lic='BSD-2-Clause'
libs_ver=1.16
libs_url=(
    https://download-mirror.savannah.gnu.org/releases/lzip/lzlib/lzlib-$libs_ver.tar.gz
    https://download.savannah.gnu.org/releases/lzip/lzlib/lzlib-$libs_ver.tar.gz
)
libs_sha=203228de911780309dad6813e51541d7ea89469784f01cb661edba080ff1b038
libs_dep=()

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --enable-silent-rules

    --disable-shared
    --enable-static
)

libs_build() {
    configure && make && make check || return $?

    pkgfile liblz -- make install
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
