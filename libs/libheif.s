# ISO/IEC 23008-12:2017 HEIF file format decoder and encoder

# shellcheck disable=SC2034
libs_lic=LGPLv3
libs_ver=1.21.2
libs_url=https://github.com/strukturag/libheif/releases/download/v$libs_ver/libheif-$libs_ver.tar.gz
libs_sha=75f530b7154bc93e7ecf846edfc0416bf5f490612de8c45983c36385aa742b42
libs_dep=( libjpeg-turbo openjpeg libpng libtiff libwebp x265 libde265 )

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
    -DWITH_OpenJPEG_ENCODER=OFF # no JPEG 200 encode

    # no h264
    -DWITH_X264=OFF
    -DWITH_OpenH264_DECODER=OFF

    # no AV1
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

    -DENABLE_PLUGIN_LOADING=OFF
    -DPLUGIN_DIRECTORY=/no-libheif-plugin
)

libs_build() {
    # bug: cmake ignores cflags of static libraries
    libs.requires libde265

    cmake.setup

    cmake.build

    pkgfile libheif -- cmake.install --component Unspecified
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
