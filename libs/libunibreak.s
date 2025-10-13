# libass is a portable subtitle renderer for the ASS/SSA (Advanced Substation Alpha/Substation Alpha) subtitle format.

# shellcheck disable=SC2034
libs_lic=Zlib
libs_ver=6.1
libs_url=https://github.com/adah1972/libunibreak/releases/download/libunibreak_${libs_ver//\./_}/libunibreak-$libs_ver.tar.gz
libs_sha=cc4de0099cf7ff05005ceabff4afed4c582a736abc38033e70fdac86335ce93f
libs_dep=()

libs_args=(
    --disable-silent-rules
    --disable-shared
    --enable-static
)

libs_build() {
    configure && 

    make && 

    library unibreak \
       include src/unibreak*.h src/linebreak.h \
       lib src/.libs/*.a \
       lib/pkgconfig *.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
