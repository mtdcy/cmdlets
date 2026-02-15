# Minimalistic client for Redis

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.3.0
libs_url=https://github.com/redis/hiredis/archive/refs/tags/v1.3.0.tar.gz
libs_sha=25cee4500f359cf5cad3b51ed62059aadfc0939b05150c1f19c7e2829123631c
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
