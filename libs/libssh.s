# C library SSHv1/SSHv2 client and server protocols
#
# shellcheck disable=SC2034
libs_ver=0.11.4
libs_url=https://www.libssh.org/files/0.11/libssh-$libs_ver.tar.xz
libs_sha=002ac320e3d66c9e100ec6576e3e84aa0c48949efde3bf5b40a2802992297701
libs_dep=( zlib openssl )

# configure args
libs_args=(
    -DWITH_ZLIB=ON
    -DWITH_SYMBOL_VERSIONING=OFF

    -DWITH_EXAMPLES=OFF

    # static only
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_STATIC_LIB=ON
)

libs_build() {
    mkdir -p build

    cmake -S . -B build

    cmake --build build

    # fix pc
    echo "Libs.private: -L\${prefix}/lib -lssl -lcrypto -lz" >> ./build/libssh.pc

    pkgfile libssh -- cmake --install build
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
