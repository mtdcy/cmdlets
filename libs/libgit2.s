# C library of Git core methods that is re-entrant and linkable
#
# shellcheck disable=SC2034
libs_lic=GPLv2
libs_ver=1.9.2
libs_url=https://github.com/libgit2/libgit2/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=6f097c82fc06ece4f40539fb17e9d41baf1a5a2fc26b1b8562d21b89bc355fe6

libs_deps=( zlib pcre2 )

# Optional dependencies:

# HTTPS: is provided by the system libraries on macOS and Windows, or by OpenSSL or mbedTLS on other Unix systems.
is_darwin || libs_deps+=( openssl )

# SSH: is provided by libssh2 or by invoking OpenSSH.
libs_deps+=( libssh2 )

# configure args
libs_args=(
    -DUSE_BUNDLED_ZLIB=OFF

    -DBUILD_CLI=OFF
    -DBUILD_TESTS=OFF
    -DBUILD_EXAMPLES=OFF

    -DBUILD_SHARED_LIBS=OFF
)

is_listed openssl   libs_deps && libs_args+=( -DUSE_HTTPS=OpenSSL   ) || libs_args+=( -DUSE_HTTPS=ON          )
is_listed libiconv  libs_deps && libs_args+=( -DUSE_ICONV=ON        ) || libs_args+=( -DUSE_ICONV=OFF         )
is_listed libssh2   libs_deps && libs_args+=( -DUSE_SSH=ON          ) || libs_args+=( -DUSE_SSH=exec          )
is_listed pcre2     libs_deps && libs_args+=( -DREGEX_BACKEND=pcre2 ) || libs_args+=( -DREGEX_BACKEND=builtin )

libs_build() {
    # pcre static: -DPCRE2_STATIC
    libs.requires -DPCRE2_STATIC 

    # could not resolve dl
    #  => cmake/FindPkgLibraries.cmake
    sed -i cmake/SelectSSH.cmake \
        -e 's/find_pkglibraries(.*)/find_library(LIBSSH2_LIBRARY NAME libssh2)/'

    cmake.setup

    cmake.build

    cmdlet.pkgfile libgit2 -- cmake.install --component Unspecified
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
