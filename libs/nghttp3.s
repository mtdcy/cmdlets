# HTTP/3 library written in C
#
# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.15.0
libs_url=https://github.com/ngtcp2/nghttp3/releases/download/v1.15.0/nghttp3-1.15.0.tar.xz
libs_sha=6da0cd06b428d32a54c58137838505d9dc0371a900bb8070a46b29e1ceaf2e0f
libs_dep=( )

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

    pkgconf lib/libnghttp3.pc -DNGHTTP3_STATICLIB

    pkgfile libnghttp3 -- cmake.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
