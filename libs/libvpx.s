# VP8/VP9 video codec

# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=1.17.0
libs_rev=2
libs_url=https://github.com/webmproject/libvpx/archive/v$libs_ver.tar.gz
libs_sha=1020f184046187baa2985dbde38e0691f49c44088bca7a1842b0236c6081dc0a

libs_args=(
    # ./configure --help shows no --prefix
    --prefix="$PREFIX"

    --enable-vp8
    --enable-vp9
    --enable-vp9-highbitdepth

    --disable-docs
    --disable-tools
    --disable-examples
    --disable-unit-tests

    --as=auto

    # static only
    --disable-shared
    --enable-static
)
    #--disable-libyuv

is_mingw && libs_args+=(--target=x86_64-win64-gcc)

libs_build() {
    configure

    make

    pkgfile libvpx -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
