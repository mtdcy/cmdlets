# shellcheck disable=SC2034

libs_desc="Data compression library"
libs_lic='BSD-2-Clause'
libs_ver=1.15
libs_url=(
    https://download-mirror.savannah.gnu.org/releases/lzip/lzlib/lzlib-$libs_ver.tar.gz
    https://download.savannah.gnu.org/releases/lzip/lzlib/lzlib-$libs_ver.tar.gz
)
libs_sha=4afab907a46d5a7d14e927a1080c3f4d7e3ca5a0f9aea81747d8fed0292377ff
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
