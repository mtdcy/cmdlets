# IETF QUIC protocol implementation
#
# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.20.0
libs_url=https://github.com/ngtcp2/ngtcp2/releases/download/v$libs_ver/ngtcp2-$libs_ver.tar.xz
libs_sha=7fb5b46bbf73dd43efbad55c707d067fdbafdca3609fc71d96e8f3068c5a6667
libs_dep=( openssl )

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
    is_listed openssl "${libs_dep[@]}" && pkgconf lib/libngtcp2.pc -lngtcp2_crypto_ossl || true

    pkgfile libngtcp2 -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
