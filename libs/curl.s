# URL retrival utility and library

# shellcheck disable=SC2034
libs_desc="Get a file from an HTTP, HTTPS or FTP server"
libs_lic="curl"
libs_ver=8.13.0
libs_url=https://curl.se/download/curl-$libs_ver.tar.bz2
libs_sha=e0d20499260760f9865cb6308928223f4e5128910310c025112f592a168e1473
libs_dep=(brotli zlib zstd libidn2 nghttp2)

is_darwin || libs_dep+=( openssl )

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # default paths
    --sysconfdir=/etc
    --with-ca-path=/etc/ssl

    --with-libidn2
    --with-zstd
    --with-zlib
    --with-brotli
    --with-nghttp2

    --with-ca-fallback # built-in CA
    --without-ca-path
    --without-ca-bundle

    --without-libssh2
    --without-libpsl
    --without-librtmp
    --disable-ldap

    --without-zsh-functions-dir
    --without-fish-functions-dir

    --disable-nls
    --disable-rpath

    --disable-doc
    --disable-man

    --disable-shared
    --enable-static
)

is_darwin && libs_args+=(
    --with-secure-transport
) || libs_args+=(
    --with-openssl
    --with-default-ssl-backend=openssl
)

libs_build() {
    apply_c89_flags || true

    configure  &&

    make V=1 &&

    #make install &&
    library libcurl                             \
            include/curl    include/curl/*.h    \
            lib             lib/.libs/libcurl.a \
            lib/pkgconfig   libcurl.pc          \
            &&

    cmdlet  ./src/curl  &&

    check curl --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
