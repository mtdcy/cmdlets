# Minimalistic client for Redis

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.4.0
libs_url=https://github.com/redis/hiredis/archive/refs/tags/v1.4.0.tar.gz
libs_sha=5fa6e719e59cd4f8ae435c52a18ac4035d135251f9ee54e7a045bccf59107ed8
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
