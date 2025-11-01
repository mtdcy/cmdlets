# High-performance, asynchronous messaging library

# shellcheck disable=SC2034
libs_lic='MPL-2.0'
libs_ver=4.3.5
libs_url=https://github.com/zeromq/libzmq/releases/download/v4.3.5/zeromq-4.3.5.tar.gz
libs_sha=6653ef5910f17954861fe72332e68b03ca6e4d9c7160eb3a8de5a5a913bfab43
libs_dep=( libsodium )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --with-libsodium

    --disable-curve-keygen
    --without-docs

    --disable-shared
    --enable-static
)

libs_build() {

    configure

    make.all

    pkgfile libzmq -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
