# GNU Transport Layer Security (TLS) Library

# shellcheck disable=SC2034
libs_lic='LGPL|GPL'
libs_ver=3.8.11
libs_url=https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-${libs_ver}.tar.xz
libs_sha=91bd23c4a86ebc6152e81303d20cf6ceaeb97bc8f84266d0faec6e29f17baa20
libs_dep=( zlib zstd brotli gmp libidn2 libtasn1 nettle libunistring )

libs_patches=(
    # https://gitlab.com/gnutls/gnutls/-/commit/f5666f8f1f653cfe2bef808a9c9b61534f279ed1
    https://gitlab.com/gnutls/gnutls/-/commit/f5666f8f1f653cfe2bef808a9c9b61534f279ed1.diff
)

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    # avoid hardcode PREFIX
    --sysconfdir=/etc

    --enable-openssl-compatibility

    --without-p11-kit
    --disable-heartbeat-support

    --disable-nls
    --disable-doc
    --disable-manpages
    --disable-valgrind-tests
    #--disable-tools     # have trouble to build static one

    --disable-shared
    --enable-static
)

is_darwin && libs_args+=(
    --with-default-trust-store-file=/etc/ssl/cert.pem
) || libs_args+=(
    --with-default-trust-store-dir=/etc/ssl/certs
)

libs_build() {
    #1. gnutls_priority_set_direct detect failed
    #export PKG_CONFIG="$PKG_CONFIG --static" ==> moved to libs.sh

    configure

    make

    make check

    pkgfile libgnutls -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
