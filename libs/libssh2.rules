# C library implementing the SSH2 protocol
#
# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=1.11.2 # HEAD
libs_rev=2
libs_url=https://github.com/libssh2/libssh2/archive/f216bbe.tar.gz
#libs_url=https://github.com/libssh2/libssh2/releases/download/libssh2-$libs_ver/libssh2-$libs_ver.tar.gz
libs_sha=e4c2c8d2498367f7d90221a9013d0f22e4594412de2e09fb4a154815fa32578c
#libs_deps=(zlib openssl)
libs_deps=(zlib mbedtls)

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --with-libz

    --disable-examples-build

    # static only
    --disable-shared
    --enable-static
)

list_has libs_deps openssl && libs_args+=(--with-crypto=openssl)
list_has libs_deps mbedtls && libs_args+=(--with-crypto=mbedtls)

libs_build() {
    bootstrap

    configure

    #if list_has libs_deps mbedtls; then
    #    # since mbedtls 3.0.0, mbedtls/ssl.h 是统一入口
    #    sed -i 's%<mbedtls/.*\.h>%mbedtls/ssl.h%g' src/mbedtls.h
    #fi

    make

    cmdlet.pkgfile libssh2 -- make install SUBDIRS=src
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
