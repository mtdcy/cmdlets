# IETF QUIC protocol implementation
#
# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.23.0
libs_url=https://github.com/ngtcp2/ngtcp2/releases/download/v$libs_ver/ngtcp2-$libs_ver.tar.xz
libs_sha=59d5b4211e96970f2d3d5e6876f73dce03414800ba04aa56835b132fce8de730

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
