# Color management engine supporting ICC profiles

# shellcheck disable=SC2034
libs_ver=2.19
libs_url=https://downloads.sourceforge.net/project/lcms/lcms/$libs_ver/lcms2-$libs_ver.tar.gz
libs_sha=49e7e134e4299733dd0eda434fa468997a28ab3d33fa397c642b03644f552216
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
    configure

    make

    inspect make install

    pkgfile liblcms2               \
            include/lcms2.h        \
            include/lcms2_plugin.h \
            lib/liblcms2.a         \
            lib/pkgconfig/lcms2.pc \

    cmdlet.install utils/transicc/transicc
    cmdlet.install utils/linkicc/linkicc
    cmdlet.install utils/jpgicc/jpgicc
    cmdlet.install utils/psicc/psicc

    cmdlet.check linkicc --help
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
