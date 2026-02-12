#
#
# shellcheck disable=SC2034

libs_lic="BSD-3-Clause"
libs_ver=1.16.0
libs_url=https://github.com/webmproject/libvpx/archive/v$libs_ver.tar.gz
libs_sha=7a479a3c66b9f5d5542a4c6a1b7d3768a983b1e5c14c60a9396edc9b649e015c

libs_args=(
    --disable-dependency-tracking

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

is_mingw && libs_args+=( --target=x86_64-win64-gcc )

libs_build() {
    configure 

    make 

    pkgfile libvpx -- make.install
}

#if [[ "$OSTYPE" == "darwin"* ]]; then
#    sed -i 's/-Wl,--no-undefined/-Wl,-undefined,error/g' build/$MAKE/Makefile
#    sed -i 's/-Wl,--no-undefined/-Wl,-undefined,error/g' Makefile
#fi

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
