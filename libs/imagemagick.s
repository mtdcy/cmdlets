# Tools and libraries to manipulate images in many formats

# shellcheck disable=SC2034
libs_ver=7.1.2-7
libs_url=https://github.com/ImageMagick/ImageMagick/archive/refs/tags/$libs_ver.tar.gz
libs_sha=d532c7be0b4fbd17d03ef311f55ad8a4845c63cb74f8725320b7d3d3c6a7a4f7
libs_dep=( freetype libraw libjpeg-turbo openjpeg png libtiff webp libheif xz bzip2 libxml2 zlib lcms2 )

# configure args
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --disable-opencl

    --with-freetype=yes

    --with-jpeg         # JPEG
    --with-openjp2      # JPEG 2000
    --with-heic         # HEIF
    --with-png
    --with-tiff
    --with-webp
    --with-raw
    
    --with-lcms

    --with-modules
    --with-zip
    --with-lqr
    
    #--with-gs-font-dir=#{HOMEBREW_PREFIX}/share/ghostscript/fonts

    # disabled features
    --without-fontconfig
    --without-gvc
    --without-jxl       # jpeg-xl
    --without-gslib
    --without-openexr
    --without-djvu
    --without-fftw
    --without-pango
    --without-wmf
    --without-x

    # openmp not ready
    --disable-openmp
    --disable-docs

    --disable-shared
    --enable-static
)

if is_darwin; then
    libs_args+=(
        --enable-osx-universal-binary=no

        ## Work around checking for clang option to support OpenMP... unsupported
        #ac_cv_prog_c_openmp="'-Xpreprocessor -fopenmp'"
        #ac_cv_prog_cxx_openmp="'-Xpreprocessor -fopenmp'"
    )
    #export LDFLAGS+=" -lomp -lz"
fi

libs_build() {
    configure && make &&

    cmdlet ./utilities/magick &&

    check magick --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
