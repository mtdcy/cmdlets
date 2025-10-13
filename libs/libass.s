# libass is a portable subtitle renderer for the ASS/SSA (Advanced Substation Alpha/Substation Alpha) subtitle format.

# shellcheck disable=SC2034
libs_lic=ISC
libs_ver=0.17.4
libs_url=https://github.com/libass/libass/releases/download/$libs_ver/libass-$libs_ver.tar.xz
libs_sha=78f1179b838d025e9c26e8fef33f8092f65611444ffa1bfc0cfac6a33511a05a
libs_dep=(fribidi freetype harfbuzz libunibreak)

libs_args=(
    --enable-silent-rules
    --disable-option-checking
    --disable-dependency-tracking
    --disable-require-system-font-provider
    --disable-shared
    --enable-static
)

is_darwin && libs_args+=(--disable-fontconfig)

libs_build() {
    # use coretext on mac

    configure &&

    make &&

    library ass \
        include/ass libass/*.h \
        lib libass/.libs/*.a \
        lib/pkgconfig libass.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
