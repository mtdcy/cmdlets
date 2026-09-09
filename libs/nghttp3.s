# HTTP/3 library written in C
#
# HTTP/3 不再运行于 TCP 之上，而是完全基于 UDP。为了实现这一点，nghttp3 和 ngtcp2 必须强强联手
#
# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.18.0
libs_rev=1
libs_url=https://github.com/ngtcp2/nghttp3/releases/download/v1.18.0/nghttp3-1.18.0.tar.xz
libs_sha=aad782c23d3f01bd4bb52c8bac7a553b631ef8115fd1612703df6183449fef19
libs_dep=()

# configure args
libs_args=(
    -DENABLE_LIB_ONLY=ON

    # static only
    -DENABLE_SHARED_LIB=OFF
    -DENABLE_STATIC_LIB=ON
)

libs_build() {

    cmake.setup

    cmake.build

    cmdlet.pkgconf lib/libnghttp3.pc -DNGHTTP3_STATICLIB

    cmdlet.pkgfile libnghttp3 -- cmake.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
