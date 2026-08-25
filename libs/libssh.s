# C library SSHv1/SSHv2 client and server protocols
#
# shellcheck disable=SC2034
libs_ver=0.11.5
libs_rev=1
libs_url=https://www.libssh.org/files/0.11/libssh-$libs_ver.tar.xz
libs_rev=1
libs_sha=6898ba9dd836d618b71dc7a4bb786a502c173cef5cafbf20fe5e0567ba4ea30c
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
