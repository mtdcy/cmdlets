# NaCl networking and cryptography library

# shellcheck disable=SC2034
libs_lic='ISC'
libs_ver=1.0.21
libs_url=https://github.com/jedisct1/libsodium/releases/download/1.0.21-RELEASE/libsodium-1.0.21.tar.gz
libs_sha=9e4285c7a419e82dedb0be63a72eea357d6943bc3e28e6735bf600dd4883feaf
libs_dep=( )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-debug

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make.all

    pkgfile $libs_name -- make install bin_SCRIPTS=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
