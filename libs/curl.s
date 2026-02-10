# URL retrival utility and library

# shellcheck disable=SC2034
libs_desc="Get a file from an HTTP, HTTPS or FTP server"
libs_lic="curl"
libs_ver=8.18.0
libs_url=https://github.com/curl/curl/releases/download/curl-8_18_0/curl-8.18.0.tar.bz2
libs_sha=ffd671a3dad424fb68e113a5b9894c5d1b5e13a88c6bdf0d4af6645123b31faf
libs_dep=( zlib zstd brotli libidn2 nghttp2 libssh2 libpsl )

libs_args=(
    # static only
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_STATIC_LIBS=ON
    -DBUILD_STATIC_CURL=ON

    # use pkg-config to find dependencies and cflags
    -DCURL_USE_PKGCONFIG=ON

    # ssl
    -DCURL_ENABLE_SSL=ON
    -DUSE_NGHTTP2=ON

    # ssh
    # libssh2 is widely used, notably in libcurl, and was historically faster for SCP,
    # but may lack some modern crypto support compared to newer libssh versions.
    -DCURL_USE_LIBSSH2=ON
    -DCURL_USE_LIBSSH=OFF

    # idn & psl
    -DUSE_LIBIDN2=ON
    -DUSE_APPLE_IDN=OFF
    -DCURL_USE_LIBPSL=ON

    # disable features
    -DCURL_USE_GSASL=OFF
    -DCURL_USE_GSSAPI=OFF

    -DBUILD_TESTING=OFF
    -DBUILD_EXAMPLES=OFF
    -DBUILD_MISC_DOCS=OFF
    -DBUILD_LIBCURL_DOCS=OFF
    -DENABLE_CURL_MANUAL=OFF
)

# ngtcp2/nghttp3
libs_dep+=( nghttp3 ngtcp2 ) && libs_args+=( -DUSE_NGTCP2=ON )

# ssl backend
libs_dep+=( openssl ) && libs_args+=( -DCURL_USE_OPENSSL=ON )

# Use Apple OS-native certificate verification
# => Apple SecTrust is only supported with Openssl/GnuTLS
is_darwin && libs_args+=( -DUSE_APPLE_SECTRUST=ON )

# Use built-in CA store of OpenSSL
is_listed openssl "${libs_dep[@]}" && libs_args+=( -DCURL_CA_FALLBACK=ON )

libs_build() {

    cmake.setup

    cmake.build

    slogcmd run src/curl -fvIL https://www.google.com || die "curl test failed"

    pkgfile libcurl -- cmake.install --component Unspecified

    cmdlet.install src/curl

    cmdlet.check curl --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
