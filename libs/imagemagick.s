# Tools and libraries to manipulate images in many formats

# shellcheck disable=SC2034
libs_ver=7.1.2-13
libs_url=https://github.com/ImageMagick/ImageMagick/archive/refs/tags/$libs_ver.tar.gz
libs_sha=3617bffe497690ffe5b731227d026db1150e138ddb129481a1e202442e558512
libs_dep=( glib freetype lcms2 libxml2 liblqr imath fftw zlib librsvg )

# configure args
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --disable-opencl

    --with-freetype=yes
    --with-lcms
    --with-lqr
    --with-fftw

    # zlib only: automagically process .gz files
    --with-zlib
    --without-bzlib
    --without-zstd
    --without-lzma
    --without-zip

    #--with-gs-font-dir=#{HOMEBREW_PREFIX}/share/ghostscript/fonts

    # disabled features
    --without-modules
    --without-fontconfig
    --without-gvc
    --without-gslib
    --without-openexr
    --without-djvu
    --without-pango
    --without-raqm
    --without-dmr
    --without-wmf
    --without-x

    --disable-docs
    --disable-shared
    --enable-static
)

is_darwin && libs_args+=( --enable-osx-universal-binary=no )

# supported formats
libs_dep+=( libraw        ) && libs_args+=( --with-raw     ) # RAW
libs_dep+=( libjpeg-turbo ) && libs_args+=( --with-jpeg    ) # JPEG
libs_dep+=( openjpeg      ) && libs_args+=( --with-openjp2 ) # JPEG 2000
libs_dep+=( libpng        ) && libs_args+=( --with-png     ) # PNG
libs_dep+=( libtiff       ) && libs_args+=( --with-tiff    ) # TIFF
libs_dep+=( libwebp       ) && libs_args+=( --with-webp    ) # WEBP
libs_dep+=( libheif       ) && libs_args+=( --with-heic    ) # HEIC
libs_dep+=( libjxl        ) && libs_args+=( --with-jxl     ) # JPEG-XL
libs_dep+=( librsvg       ) && libs_args+=( --with-rsvg    ) # SVG

# openmp
is_darwin || libs_args+=( --enable-openmp )

libs_build() {
    configure

    make

    # testing
    check_magick_format() {
        ./utilities/magick identify -list format | grep -w " $1" || die "missing $1 support"
    }

    for x in "${libs_dep[@]}"; do
        case "$x" in
            libraw)         check_magick_format RAW     ;;
            libjpeg-turbo)  check_magick_format JPEG    ;;
            openjpeg)       check_magick_format J2K     ;;
            libjxl)         check_magick_format JXL     ;;
            libpng)         check_magick_format PNG     ;;
            libtiff)        check_magick_format TIFF    ;;
            libwebp)        check_magick_format WEBP    ;;
            libheif)        check_magick_format HEIC    ;;
            librsvg)        check_magick_format SVG     ;;
        esac
    done

    # install configlib and configshare to the same directory.
    sed -i '/CONFIGURE_PATH/s/etc/share/' Makefile

    cmdlet.pkgfile ImageMagick -- make install-configlibDATA install-configshareDATA

    cmdlet.install ./utilities/magick

    cmdlet.check magick --version

    cmdlet.caveats << EOF
static built ImageMagick

$(./utilities/magick -version)

Configuration and resource files:

    cmdlets.sh install ImageMagick
    cmdlets.sh link share/ImageMagick-${libs_ver%%.*} ~/.config/ImageMagick

    OR you can set MAGICK_CONFIGURE_PATH to where the files are.
EOF
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
