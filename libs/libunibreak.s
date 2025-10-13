# libass is a portable subtitle renderer for the ASS/SSA (Advanced Substation Alpha/Substation Alpha) subtitle format.

# shellcheck disable=SC2034
upkg_lic=Zlib
upkg_ver=6.1
upkg_url=https://github.com/adah1972/libunibreak/releases/download/libunibreak_${upkg_ver//\./_}/libunibreak-$upkg_ver.tar.gz
upkg_sha=cc4de0099cf7ff05005ceabff4afed4c582a736abc38033e70fdac86335ce93f
upkg_dep=()

upkg_args=(
    --disable-silent-rules
    --disable-shared
    --enable-static
)

upkg_static() {
    configure && 

    make && 

    library unibreak \
       include src/unibreak*.h src/linebreak.h \
       lib src/.libs/*.a \
       lib/pkgconfig *.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
