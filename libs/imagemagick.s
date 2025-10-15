# Tools and libraries to manipulate images in many formats

# shellcheck disable=SC2034
libs_ver=7.1.2-5
libs_url=https://imagemagick.org/archive/releases/ImageMagick-$libs_ver.tar.xz
libs_sha=3f8a2ef3744a704edec90734106107a6f4548e65a30d91d4dedce4c17c6f9e75
libs_dep=( freetype libraw libjpeg-turbo jasper png tiff openjpeg webp libheif xz bzip2 libxml2 zlib )

# configure args
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --disable-opencl

    --with-freetype=yes
    --with-gvc=no
    --with-modules
    --with-openjp2
    --with-jpeg=yes
    --with-webp=yes
    --with-heic=yes
    --with-raw=yes
    --with-zip=yes
    --with-lqr
    
    #--with-gs-font-dir=#{HOMEBREW_PREFIX}/share/ghostscript/fonts

    --without-fontconfig
    --without-jxl   # jpeg-xl
    --without-gslib
    --without-openexr
    --without-djvu
    --without-fftw
    --without-pango
    --without-wmf
    --without-lcms
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
    configure && make || return 1

    cmdlet ./utilities/magick &&

    check magick --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
