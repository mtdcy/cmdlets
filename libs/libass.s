# libass is a portable subtitle renderer for the ASS/SSA (Advanced Substation Alpha/Substation Alpha) subtitle format.

# shellcheck disable=SC2034
libs_lic=ISC
libs_ver=0.17.5
libs_url=https://github.com/libass/libass/releases/download/$libs_ver/libass-$libs_ver.tar.xz
libs_sha=2dca25c0e0c837ddf00b52011b3f82cac1e4ddd3ad018227806b0c2288864acc
libs_dep=( fribidi freetype harfbuzz libunibreak )

libs_args=(
    --enable-silent-rules
    --disable-option-checking
    --disable-dependency-tracking

    #--disable-require-system-font-provider

    # static only
    --disable-shared
    --enable-static
)

# libass uses coretext on macOS, fontconfig on Linux
if is_darwin; then
    libs_args+=( --disable-fontconfig --enable-coretext )
else
    libs_dep+=( fontconfig )
    libs_args+=( --enable-fontconfig --disable-coretext )
fi

libs_build() {
    configure

    make

    pkgfile libass -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
