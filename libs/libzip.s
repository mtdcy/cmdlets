# shellcheck disable=SC2034
libs_desc="C library for reading, creating, and modifying zip archives"
libs_lic="BSD-3-Clause"

libs_ver=1.11.4
libs_url=https://libzip.org/download/libzip-1.11.4.tar.xz
libs_sha=8a247f57d1e3e6f6d11413b12a6f28a9d388de110adc0ec608d893180ed7097b
libs_dep=( xz zstd bzip2 )

libs_args=(
    -DENABLE_GNUTLS=OFF
    -DENABLE_MBEDTLS=OFF
    -DBUILD_REGRESS=OFF

    -DBUILD_DOC=OFF
    -DBUILD_TOOLS=OFF
    -DBUILD_EXAMPLES=OFF

    # static only
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_STATIC_LIBS=ON
)

# openssl?
is_darwin && libs_args+=( -DENABLE_OPENSSL=OFF ) || libs_dep+=( openssl )

libs_build() {

    cmake.setup

    cmake.build

    cmdlet.pkgfile libzip -- cmake.install --component Unspecified
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
