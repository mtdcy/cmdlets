# Library for manipulating PNG images
#
# shellcheck disable=SC2034

libs_lic="libpng-2.0"
libs_ver=1.6.50
libs_url=https://downloads.sourceforge.net/libpng/libpng16/libpng-$libs_ver.tar.xz
libs_sha=4df396518620a7aa3651443e87d1b2862e4e88cad135a8b93423e01706232307
libs_dep=(zlib)

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --enable-hardware-optimizations
    --enable-unversioned-links
    --enable-unversioned-libpng-pc
    --disable-shared
    --enable-static
)

libs_build() {
    # force configure
    rm CMakeLists.txt

    configure &&

    make &&

    # make install
    library libpng16:libpng                         \
            include                                 \
                png.h pngconf.h pnglibconf.h        \
            include/libpng16                        \
                png.h pngconf.h pnglibconf.h        \
            lib                                     \
                .libs/libpng16.a .libs/libpng16.la  \
            lib/pkgconfig                           \
                libpng16.pc &&

    cmdlet ./pngfix &&
    cmdlet ./pngimage &&
    cmdlet ./pngtest &&
    cmdlet ./libpng16-config libpng16-config libpng-config &&

    check pngtest --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
