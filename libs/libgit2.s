# C library of Git core methods that is re-entrant and linkable
#
# shellcheck disable=SC2034
libs_lic=GPLv2
libs_ver=1.9.7
libs_rev=2
libs_url=https://github.com/libgit2/libgit2/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=1a4fbe7589e814777ae76b64734ad80f4ecad22cd33a22682a2aaea4ae5375e7

libs_deps=(zlib pcre2 libssh2 libiconv)
# -DUSE_ICONV=OFF not working

# Optional dependencies:

# HTTPS: is provided by the system libraries on macOS and Windows, or by OpenSSL or mbedTLS on other Unix systems.
#is_darwin || libs_deps+=(openssl)

# configure args
libs_args=(
    -DUSE_BUNDLED_ZLIB=OFF

    -DUSE_ICONV=ON

    -DBUILD_CLI=OFF
    -DBUILD_TESTS=OFF
    -DBUILD_EXAMPLES=OFF

    -DBUILD_SHARED_LIBS=OFF

    # prebuilts/x86_64-linux-gnu/include/mbedtls/md.h:246:8: error: unknown type name 'inline'
    # mbedtls uses c99 : -std=c90 => -std=c99
    -DCMAKE_C_STANDARD=99
)

is_listed pcre2     libs_deps && libs_args+=(-DREGEX_BACKEND=pcre2) || libs_args+=(-DREGEX_BACKEND=builtin)
is_listed openssl   libs_deps && libs_args+=(-DUSE_HTTPS=OpenSSL)   || libs_args+=(-DUSE_HTTPS=ON)
is_listed mbedtls   libs_deps && libs_args+=(-DUSE_HTTPS=mbedTLS)   || libs_args+=(-DUSE_HTTPS=ON)
# SSH: is provided by libssh2 or by invoking OpenSSH.
is_listed libssh2   libs_deps && libs_args+=(-DUSE_SSH=ON)          || libs_args+=(-DUSE_SSH=exec)

libs_build() {
    # pcre static: -DPCRE2_STATIC
    libs.requires -DPCRE2_STATIC
    # /opt/zig/lib/libc/include/generic-glibc/regexp.h:29:2: error: "The GNU C Library no longer implements <regexp.h>."
    #  -isystem 破坏了头文件的搜索优先级顺序
    find . -name CMakeLists.txt -exec sed -i '/target_include_directories/s/SYSTEM//' {} +

    # could not resolve dl
    #  => cmake/FindPkgLibraries.cmake
    sed -i cmake/SelectSSH.cmake \
        -e 's/find_pkglibraries(.*)/find_library(LIBSSH2_LIBRARY NAME libssh2)/'

    cmake.setup

    cmake.build

    cmdlet.pkgconf libgit2.pc -liconv

    cmdlet.pkgfile libgit2 -- cmake.install --component Unspecified

    "$NM" -g "$PREFIX/lib/libgit2.a" | grep -F libiconv_open || die "broken linkage"

    "$PKG_CONFIG" --libs libgit2 | grep -- -liconv || die "broken linkage"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
