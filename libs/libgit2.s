# C library of Git core methods that is re-entrant and linkable
#
# shellcheck disable=SC2034
libs_ver=1.9.1
libs_url=https://github.com/libgit2/libgit2/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=14cab3014b2b7ad75970ff4548e83615f74d719afe00aa479b4a889c1e13fc00
libs_dep=( zlib libssh2 libiconv )

is_darwin || libs_dep+=( openssl )

# configure args
libs_args=(
    -DUSE_BUNDLED_ZLIB=OFF
    -DUSE_SSH=ON
    -DUSE_ICONV=OFF     # link to apple iconv?

    -DBUILD_CLI=OFF
    -DBUILD_TESTS=OFF
    -DBUILD_EXAMPLES=OFF

    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    mkdir -p build

    cmake -S . -B build

    cmake --build build

    pkgfile libgit2 -- cmake --install build
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
