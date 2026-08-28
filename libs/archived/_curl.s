# URL retrival utility and library

# shellcheck disable=SC2034
libs_desc="Get a file from an HTTP, HTTPS or FTP server"
libs_lic="curl"
libs_ver=8.13.0
libs_url=https://curl.se/download/curl-$libs_ver.tar.bz2
libs_sha=e0d20499260760f9865cb6308928223f4e5128910310c025112f592a168e1473
libs_dep=(zlib zstd brotli libidn2 nghttp2 nghttp3 ngtcp2 libssh2)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # default paths
    --sysconfdir=/etc

    # compression
    --with-zlib
    --with-zstd
    --with-brotli

    # IDN
    --without-apple-idn
    --with-libidn2

    # ssl
    --with-ssl
    --with-nghttp2
    --with-nghttp3
    --with-ngtcp2

    # ssh v2
    --with-libssh2
    --without-libssh

    # disabled features
    --without-gssapi    # GSS-API
    --without-libpsl
    --without-librtmp
    --disable-ldap

    --without-zsh-functions-dir
    --without-fish-functions-dir

    --disable-nls

    --disable-docs
    --disable-manual

    --disable-shared
    --enable-static

    # CA
    --without-ca-bundle
    --without-ca-path
    --with-ca-fallback  # built-in CA store of the SSL library
    # embed ca in curl
    #--with-ca-embed=/etc/ssl/certs/ca-certificates.crt
)

# ssl backend
if is_darwin; then
    # Apple OS native SSL/TLS
    libs_args+=( --with-secure-transport )
else
    libs_dep+=( openssl )
    libs_args+=(
        --with-openssl
        --with-default-ssl-backend=openssl
        --without-openssl-quic
    )
fi

libs_build() {
    libs.requires.c89 || true

    configure

    make V=1

    slogcmd ./src/curl -fsIL https://www.google.com

    # edit only top SUBDIRS => install library only
    TOP_SUBDIRS=( lib include )
    sed -i Makefile \
        -e 's/SUBDIRS/TOP_SUBDIRS/g'

    # fix curl-config
    #  1. eval all echo command
    sed -i curl-config \
        -e 's/\s\+\<echo\>/eval &/g'

    pkgfile libcurl -- make install bin_PROGRAMS=

    cmdlet.install src/curl

    cmdlet.check curl --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
