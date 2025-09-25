#
#
# shellcheck disable=SC2034

upkg_lic="BSD-3-Clause"
upkg_ver=1.15.2
upkg_url=https://github.com/webmproject/libvpx/archive/v$upkg_ver.tar.gz
upkg_zip=libvpx-$upkg_ver.tar.gz
upkg_sha=26fcd3db88045dee380e581862a6ef106f49b74b6396ee95c2993a260b4636aa

upkg_args=(
    --enable-vp8
    --enable-vp9
    --disable-examples
    --disable-unit-tests
    --enable-vp9-highbitdepth
    #--extra-cflags=\"$CFLAGS\"
    #--extra-cxxflags=\"$CPPFLAGS\"
    --as=auto
    --disable-shared
    --enable-static
)
    #--disable-libyuv

upkg_static() {
    configure && make &&
    
    library vpx \
        include/vpx vpx/vp*.h \
        lib *.a \
        lib/pkgconfig vpx.pc
}

#if [[ "$OSTYPE" == "darwin"* ]]; then
#    sed -i 's/-Wl,--no-undefined/-Wl,-undefined,error/g' build/$MAKE/Makefile
#    sed -i 's/-Wl,--no-undefined/-Wl,-undefined,error/g' Makefile
#fi

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
