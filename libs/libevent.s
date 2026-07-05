# Asynchronous event library
#
# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=2.1.13
libs_url=https://github.com/libevent/libevent/archive/refs/tags/release-$libs_ver-stable.tar.gz
libs_sha=1a0885e17dc78afbaeddf13cf849f9238bbc24acdc178464a0d1934d7c5ffbd5
libs_dep=( openssl )

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-pic
    --enable-openssl

    --disable-samples
    --disable-debug-mode
    --disable-doxygen-html

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    configure && make || return $?

    pkgfile libevent -- make install
}
# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
