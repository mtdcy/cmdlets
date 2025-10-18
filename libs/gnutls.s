# GNU Transport Layer Security (TLS) Library

# shellcheck disable=SC2034
libs_lic='LGPL|GPL'
libs_ver=3.8.10
libs_url=https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-${libs_ver}.tar.xz
libs_sha=db7fab7cce791e7727ebbef2334301c821d79a550ec55c9ef096b610b03eb6b7
libs_dep=(zlib zstd brotli gmp libidn2 libtasn1 nettle libunistring)

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --without-p11-kit
    --enable-openssl-compatibility

    --disable-nls

    --disable-doc
    --disable-manpages
    --disable-valgrind-tests
    --disable-tools     # have trouble to build static one

    --disable-shared
    --enable-static
)

libs_build() {
    #1. gnutls_priority_set_direct detect failed
    #export PKG_CONFIG="$PKG_CONFIG --static" ==> moved to libs.sh

    configure &&

    make &&

    make check &&

    pkginst libgnutls                                 \
        include/gnutls  lib/includes/gnutls/gnutls*.h \
        lib             lib/.libs/libgnutls*.a        \
        lib/pkgconfig   lib/gnutls.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
