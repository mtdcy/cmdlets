# libass is a portable subtitle renderer for the ASS/SSA (Advanced Substation Alpha/Substation Alpha) subtitle format.

# shellcheck disable=SC2034
libs_lic=ISC
libs_ver=0.17.5
libs_rev=1
libs_url=https://github.com/libass/libass/releases/download/$libs_ver/libass-$libs_ver.tar.xz
libs_sha=2dca25c0e0c837ddf00b52011b3f82cac1e4ddd3ad018227806b0c2288864acc

libs_deps=(freetype harfbuzz fribidi libunibreak libiconv)
# harfbuzz & fribidi is mandatory for libass

libs_args=(
    # static only
    --enable-static --disable-shared

    #--disable-require-system-font-provider
)

# libass uses coretext on macOS, fontconfig on Linux
case "$LIBS_TARGET" in
    darwin)
        libs_args+=(--disable-fontconfig --enable-coretext)
        ;;
    windows | cygwin)
        libs_deps+=(fontconfig)
        libs_args+=(--enable-fontconfig --disable-directwrite)
        ;;
    *)
        libs_deps+=(fontconfig)
        libs_args+=(--enable-fontconfig --disable-coretext)
        ;;
esac

list_has libs_deps libiconv && libs_args+=(ac_cv_search_libiconv_open=-liconv)

libs_build() {
    configure

    make

    # make sure we are linked to libiconv:libiconv_open
    slogcmd "$NM" -g libass/.libs/libass.a | grep -F libiconv_open || die "broken linkage"

    cmdlet.pkgfile libass -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
