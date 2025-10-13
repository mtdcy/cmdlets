# OpenJPEG is an open-source JPEG 2000 codec written in C language.
#
# shellcheck disable=SC2034

upkg_ver=2.5.4
upkg_url=https://github.com/uclouvain/openjpeg/archive/v$upkg_ver.tar.gz
upkg_zip=openjpeg-$upkg_ver.tar.gz
upkg_sha=a695fbe19c0165f295a8531b1e4e855cd94d0875d2f88ec4b61080677e27188a

upkg_args=(
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_STATIC_LIBS=ON
    # no applications
    -DBUILD_CODEC=OFF
)

upkg_static() {
    cmake . && 

    make && 

    library openjp2 \
        include/openjpeg-${upkg_ver%.*} src/lib/openjp2/openjpeg.h src/lib/openjp2/opj_config.h \
        lib bin/libopenjp2.a \
        lib/pkgconfig libopenjp2.pc  \
        lib/cmake/openjpeg-${upkg_ver%.*} *.cmake
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
