# BSD-3-Clause
#
# shellcheck disable=SC2034

libs_lic="BSD"
libs_ver=1.3.6
libs_url=(
    https://github.com/xiph/libogg/releases/download/v$libs_ver/libogg-$libs_ver.tar.gz
    https://downloads.xiph.org/releases/libogg/libogg-$libs_ver.tar.gz
)
libs_sha=83e6704730683d004d20e21b8f7f55dcb3383cdf84c0daedf30bde175f774638

libs_args=(
    -DINSTALL_DOCS=OFF

    # static
    -DBUILD_SHARED_LIBS=FALSE
)

libs_build() {
    mkdir -p build && cd build 

    cmake .. && make || return $?

    pkgfile libogg -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
