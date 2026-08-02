# IETF QUIC protocol implementation
#
# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.25.0
libs_url=https://github.com/ngtcp2/ngtcp2/releases/download/v$libs_ver/ngtcp2-$libs_ver.tar.xz
libs_sha=2a34d2484ba17847a5d11965704e9dd0fac4c6d8efc75ffe1ec7de66d8c6b6fb

libs_deps=( openssl )

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --with-openssl

    --without-libev
    --without-libnghttp3

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    slogcmd ./buildconf

    configure

    make

    # fix libngtcp2.pc
    is_listed openssl libs_deps &&
    pkgconf lib/libngtcp2.pc -lngtcp2_crypto_ossl openssl || true

    pkgconf lib/libngtcp2.pc -DNGTCP2_STATICLIB

    pkgfile libngtcp2 -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
