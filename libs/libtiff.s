# TIFF library and utilities
#
# shellcheck disable=SC2034

libs_lic="libtiff"
libs_ver=4.7.1
libs_url=https://download.osgeo.org/libtiff/tiff-$libs_ver.tar.gz
libs_sha=f698d94f3103da8ca7438d84e0344e453fe0ba3b7486e04c5bf7a9a3fabe9b69
libs_dep=(zlib xz libjpeg-turbo zstd)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-lzma
    --enable-zstd
    --disable-libdeflate

    # loop dependency between libtiff & webp
    --disable-webp

    --disable-shared
    --enable-static
    --without-x
)

libs_build() {
    configure

    make

    pkgfile libtiff -- make.install SUBDIRS=libtiff

    IFS=' ' read -r -a tools < <(find tools -name "*.o" | xargs)

    for x in "${tools[@]%.o}"; do
        test -x "$x" || continue

        cmdlet.install "$x"
        cmdlet.check "$x"
    done

}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
