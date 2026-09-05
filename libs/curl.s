# URL retrival utility and library

# shellcheck disable=SC2034
libs_desc="Get a file from an HTTP, HTTPS or FTP server"
libs_lic="curl"
libs_ver=8.22.0
libs_rev=1
libs_url=https://github.com/curl/curl/releases/download/curl-${libs_ver//./_}/curl-$libs_ver.tar.bz2
libs_sha=5d956a6a22b3c279f50c421ee5d3c9e9d660cb6f115dcf881b579e952130549c
libs_deps=(zlib brotli libidn2 ngtcp2 nghttp2 nghttp3 libssh2 openssl)

# libssh2 is widely used, notably in libcurl, and was historically faster for SCP,
# but may lack some modern crypto support compared to newer libssh versions.

libs_args=(
    # static only
    --enable-static --disable-shared

    --enable-optimize
    --enable-ipv6

    # disable features
    --disable-ares
    --without-libgsasl
    --disable-docs
    --disable-manual
)

if is_cygwin; then
    # 不搜索 PATH, 回落到文件所在目录 或 内置 ca 证书
    libs_args+=(--disable-ca-search)
fi

if list_has libs_deps openssl; then
    # Use built-in CA store of OpenSSL
    libs_args+=(--with-openssl --with-ca-fallback)

    # Use Apple OS-native certificate verification
    # => Apple SecTrust is only supported with Openssl/GnuTLS
    is_darwin && libs_args+=(--with-apple-sectrust)
fi

list_has libs_deps zlib     && libs_args+=(--with-zlib)     || libs_args+=(--without-zlib)
list_has libs_deps brotli   && libs_args+=(--with-brotli)   || libs_args+=(--without-brotli)
list_has libs_deps libssh2  && libs_args+=(--with-libssh2)  || libs_args+=(--without-libssh2)
list_has libs_deps libpsl   && libs_args+=(--with-libpsl)   || libs_args+=(--without-libpsl)
list_has libs_deps libidn2  && libs_args+=(--with-libidn2)  || libs_args+=(--without-libidn2)
list_has libs_deps ngtcp2   && libs_args+=(--with-ngtcp2)   || libs_args+=(--without-ngtcp2)
list_has libs_deps nghttp2  && libs_args+=(--with-nghttp2)  || libs_args+=(--without-nghttp2)
list_has libs_deps nghttp3  && libs_args+=(--with-nghttp3)  || libs_args+=(--without-nghttp3)

libs_build() {
    # force posix thread for cygwin
    #is_cygwin && is_posix && libs.requires -DUSE_THREADS_POSIX

    slogcmd curl --insecure https://curl.se/ca/cacert.pem -o cacert.pem || die "fetch cacert.pem failed."

    configure --with-ca-embed="$PWD/cacert.pem"

    make

    slogcmd run src/curl -4 -fvIL https://www.google.com || die "curl test failed"

    pkgconf libcurl.pc -DCURL_STATICLIB

    pkgfile libcurl -- make.install bin_PROGRAMS=

    cmdlet.install src/curl

    cmdlet.check curl --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
