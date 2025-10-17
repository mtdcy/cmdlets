# Asynchronous event library
#
# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=2.1.12
libs_url=https://github.com/libevent/libevent/archive/refs/tags/release-$libs_ver-stable.tar.gz
libs_sha=7180a979aaa7000e1264da484f712d403fcf7679b1e9212c4e3d09f5c93efc24
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
