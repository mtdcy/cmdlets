# ISO/IEC 23008-12:2017 HEIF file format decoder and encoder

# shellcheck disable=SC2034
libs_ver=1.20.2
libs_url=https://github.com/strukturag/libheif/releases/download/v$libs_ver/libheif-$libs_ver.tar.gz
libs_sha=68ac9084243004e0ef3633f184eeae85d615fe7e4444373a0a21cebccae9d12a
libs_dep=( libjpeg-turbo openjpeg png libtiff webp x265 libde265 )

# configure args
libs_args=(
    # h265 decode & encode
    -DWITH_X265=ON          # h265 encoder
    -DWITH_LIBDE265=ON      # h265 decoder
    -DWITH_KVAZAAR=OFF

    # jpeg
    -DWITH_JPEG_DECODER=ON      # libjpeg decode
    -DWITH_JPEG_ENCODER=ON      # libjpeg encode
    -DWITH_OpenJPEG_DECODER=ON  # JPEG 2000 decode

    # h264
    -DWITH_OpenH264_DECODER=OFF

    # AV1
    -DWITH_RAV1E=OFF        
    -DWITH_SvtEnc=OFF
    -DWITH_AOM_ENCODER=OFF
    -DWITH_AOM_DECODER=OFF
    -DWITH_DAV1D=OFF

    # not ready
    -DWITH_LIBSHARPYUV=OFF

    # misc
    -DWITH_GDK_PIXBUF=OFF
    -DWITH_VVDEC=OFF
    -DWITH_VVENC=OFF

    -DWITH_EXAMPLES=OFF
    -DBUILD_TESTING=OFF

    # static
    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    rm -f static || true
    mkdir -p static && cd static

    cmake .. && make || return 1

    inspect make install &&

    pkgfile libheif                  \
            include/libheif          \
            lib/libheif.a            \
            lib/pkgconfig/libheif.pc \
            lib/cmake/libheif
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
