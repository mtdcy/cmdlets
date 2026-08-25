# Minimalistic client for Redis

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.4.1
libs_rev=1
libs_url=https://github.com/redis/hiredis/archive/refs/tags/v1.4.1.tar.gz
libs_sha=ca3180359a8b1275838a45415851f8cd5c411e27bdbf18f4823012e45507d2e4
libs_dep=( openssl )

libs_args=(
    -DENABLE_SSL=ON

    -DDISABLE_TESTS=ON
    
    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    cmake.setup

    cmake.build

    pkgfile libhiredis -- cmake.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
