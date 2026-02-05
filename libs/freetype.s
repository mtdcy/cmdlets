# FreeType is a freely available software library to render fonts.

# shellcheck disable=SC2034
libs_lic=FTL
libs_ver=2.14.0
libs_url=https://downloads.sourceforge.net/project/freetype/freetype2/$libs_ver/freetype-$libs_ver.tar.xz
libs_sha=f8dfa8f15ef0576738dfb55b2e6e6b172fd5d09b6f03785a1df03239549f64d2
libs_dep=(zlib bzip2 brotli libpng)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-pic
    --with-zlib
    --with-bzip2        # bzip2 compreesed fonts
    --with-png          # OpenType
    --with-brotli       # WOFF2

    --without-librsvg   # OpenType SVG fonts
    # https://stackoverflow.com/questions/29747552/undefined-reference-to-hb-ft-font-create-on-linux
    --without-harfbuzz  # auto-hinting of OpenType

    # no freetype-config which hardcoded PREFIX
    --disable-freetype-config

    --disable-shared
    --enable-static
)

libs_build() {
    # for objs/apinames
    export CCexe_CFLAGS="$CFLAGS"

    configure && make || return 1

    #inspect make install

    pkgfile libfreetype2 -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
