# Color management engine supporting ICC profiles

# shellcheck disable=SC2034
libs_ver=2.17
libs_url=https://downloads.sourceforge.net/project/lcms/lcms/$libs_ver/lcms2-$libs_ver.tar.gz
libs_sha=d11af569e42a1baa1650d20ad61d12e41af4fead4aa7964a01f93b08b53ab074
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
