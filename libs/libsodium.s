# NaCl networking and cryptography library

# shellcheck disable=SC2034
libs_lic='ISC'
libs_ver=1.0.22
libs_url=https://github.com/jedisct1/libsodium/releases/download/1.0.22-RELEASE/libsodium-1.0.22.tar.gz
libs_sha=adbdd8f16149e81ac6078a03aca6fc03b592b89ef7b5ed83841c086191be3349
libs_dep=( )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-debug

    --disable-shared
    --enable-static
)

libs_build() {
    # Allow type conversion between vectors on Arm Linux
    is_linux && is_arm64 && export CFLAGS+=" -flax-vector-conversions"

    configure

    make

    pkgfile $libs_name -- make.install bin_SCRIPTS=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
