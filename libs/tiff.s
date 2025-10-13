# TIFF library and utilities
#
# shellcheck disable=SC2034

libs_lic="libtiff"
libs_ver=4.7.1
libs_url=https://download.osgeo.org/libtiff/tiff-$libs_ver.tar.gz
libs_sha=f698d94f3103da8ca7438d84e0344e453fe0ba3b7486e04c5bf7a9a3fabe9b69
libs_dep=(zlib xz turbojpeg zstd)

libs_args=(
    --disable-dependency-tracking
    --disable-webp
    --enable-lzma
    --enable-zstd
    --disable-webp     # loop dependency between tiff & webp
    --disable-shared
    --enable-static
    --without-x
)

libs_build() {
    # force configure
    rm CMakeLists.txt

    configure && 

    make &&
    
    library tiff \
       include libtiff/tiff*.h \
       lib libtiff/.libs/libtiff.a \
       lib/pkgconfig libtiff-${libs_ver%%.*}.pc &&
    
       library tiffxx \
       include libtiff/tiffio.hxx \
       lib libtiff/.libs/libtiffxx.a &&

    cmdlet tools/tiffinfo &&
    cmdlet tools/tiffcmp &&
    cmdlet tools/raw2tiff &&

    check tiffinfo
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
