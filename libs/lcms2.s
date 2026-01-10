# Color management engine supporting ICC profiles

# shellcheck disable=SC2034
libs_ver=2.18
libs_url=https://downloads.sourceforge.net/project/lcms/lcms/$libs_ver/lcms2-$libs_ver.tar.gz
libs_sha=ee67be3566f459362c1ee094fde2c159d33fa0390aa4ed5f5af676f9e5004347
libs_dep=( zlib libjpeg-turbo libtiff )

# configure args
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-zlib
    --with-jpeg
    --with-tiff

    --disable-docs

    --disable-shared
    --enable-static
)

libs_build() {
    configure && make || return 1

    inspect make install &&

    pkgfile liblcms2               \
            include/lcms2.h        \
            include/lcms2_plugin.h \
            lib/liblcms2.a         \
            lib/pkgconfig/lcms2.pc \
            && 

    cmdlet  ./utils/linkicc/linkicc   &&
    cmdlet  ./utils/transicc/transicc &&
    cmdlet  ./utils/psicc/psicc       &&

    # install: cannot stat './utils/jpgicc/jpgicc': No such file or directory
    #cmdlet  ./utils/jpgicc/jpgicc     &&

    check linkicc --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
