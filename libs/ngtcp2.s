# IETF QUIC protocol implementation
#
# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.24.0
libs_url=https://github.com/ngtcp2/ngtcp2/releases/download/v$libs_ver/ngtcp2-$libs_ver.tar.xz
libs_sha=7fa5ec2be0f0cbed8bc4ec89c0787dfa9d8ce678f1ed9477c52f30eb1a591207

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
