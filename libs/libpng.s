# Library for manipulating PNG images
#
# shellcheck disable=SC2034

libs_lic="libpng-2.0"
libs_ver=1.6.50
libs_url=https://downloads.sourceforge.net/libpng/libpng16/libpng-$libs_ver.tar.xz
libs_sha=4df396518620a7aa3651443e87d1b2862e4e88cad135a8b93423e01706232307
libs_dep=(zlib)

libs_args=(
    --disable-option-checking
    --enable-silent-rules

    --enable-hardware-optimizations

    --enable-unversioned-links
    --enable-unversioned-libpng-pc

    --enable-pic

    # no libpng-config => make install fails
    #--without-binconfigs

    --disable-shared
    --enable-static
)

libs_build() {
    configure && make || return $?

    # binaries been included too
    pkgfile libpng -- make install &&

    cmdlet ./pngfix       &&
    cmdlet ./pngtest      &&
    cmdlet ./pngimage     &&
    cmdlet ./png-fix-itxt &&

    check  pngtest --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
