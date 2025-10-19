# HTTP/3 library written in C
#
# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.12.0
libs_url=https://github.com/ngtcp2/nghttp3/releases/download/v$libs_ver/nghttp3-$libs_ver.tar.xz
libs_sha=6ca1e523b7edd75c02502f2bcf961125c25577e29405479016589c5da48fc43d
libs_dep=( )

# configure args
libs_args=(
    -DENABLE_LIB_ONLY=ON

    # static only
    -DENABLE_SHARED_LIB=OFF
    -DENABLE_STATIC_LIB=ON
)

libs_build() {
    mkdir -p build

    cmake -S . -B build

    cmake --build build

    pkgfile libnghttp3 -- cmake --install build
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
