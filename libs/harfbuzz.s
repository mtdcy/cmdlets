# OpenType text shaping engine
#
# shellcheck disable=SC2034

libs_lic="MIT"
libs_ver=8.5.0
libs_url=https://github.com/harfbuzz/harfbuzz/releases/download/$libs_ver/harfbuzz-$libs_ver.tar.xz
libs_sha=77e4f7f98f3d86bf8788b53e6832fb96279956e1c3961988ea3d4b7ca41ddc27
libs_dep=(freetype)

#libs_args=(
#    -Dfreetype=enabled
#    -Dglib=disabled         # for Pango
#    -Dgobject=disabled      # for GNOME
#    -Dgraphite2=disabled    # for texlive or LibreOffice
#    -Dcairo=disabled        # optional
#    -Dchafa=disabled        # optional
#    -Dtests=disabled
#    -Ddocs=disabled
#)
#is_darwin && libs_args+=(-Dcoretext=enabled)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-glib=no
    --with-gobject=no
    --with-graphite2=no
    --with-cairo=no
    --with-chafa=no
    --with-tests=no
    --with-introspection=no
    --with-docs=no

    --disable-shared
    --enable-static

    # it seems harfbuzz has trouble with 'pkg-config --static'
    #LIBS="-lbrotlidec -lbrotlicommon -lpng -lz"
)

is_darwin && libs_args+=(--with-coretext=yes)

libs_build() {
    #meson setup build &&
    #meson setup --reconfigure build "${libs_args[@]}" &&
    #meson compile -C build --verbose &&
    #meson install -C build

    rm -f CMakeLists.txt meson.build # force configure

    #export PKG_CONFIG="$PKG_CONFIG --static" # => moved to libs.sh

    configure &&

    make V=1 &&

    library harfbuzz \
       include/harfbuzz src/*.h \
       lib src/.libs/*.a \
       lib/pkgconfig  src/*.pc \
       lib/cmake/harfbuzz src/*.cmake
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
