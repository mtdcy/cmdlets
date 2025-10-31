# URL retrival utility and library

# shellcheck disable=SC2034
libs_desc="Get a file from an HTTP, HTTPS or FTP server"
libs_lic="curl"
libs_ver=8.13.0
libs_url=https://curl.se/download/curl-$libs_ver.tar.bz2
libs_sha=e0d20499260760f9865cb6308928223f4e5128910310c025112f592a168e1473
libs_dep=(brotli zlib zstd libidn2 nghttp2 libssh2)

is_darwin || libs_dep+=( openssl )

libs_args=(
    # static only
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_STATIC_LIBS=ON
    -DBUILD_STATIC_CURL=ON

    -DCURL_USE_LIBPSL=OFF
    -DUSE_NGTCP2=OFF

    -DBUILD_LIBCURL_DOCS=OFF
    -DBUILD_MISC_DOCS=OFF
    -DENABLE_CURL_MANUAL=OFF

    -DBUILD_TESTING=OFF
    -DBUILD_EXAMPLES=OFF

    # default paths
    #--sysconfdir=/etc
)

libs_build() {

    cmake.setup

    cmake.build

    slogcmd ./build/src/curl -fsIL https://www.google.com

    pkgfile libcurl -- cmake.install --component Unspecified

    cmdlet  ./build/src/curl

    check curl --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
