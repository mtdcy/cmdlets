# OpenType text shaping engine
#
# shellcheck disable=SC2034

libs_lic="MIT"
libs_ver=8.5.0
libs_url=https://github.com/harfbuzz/harfbuzz/releases/download/$libs_ver/harfbuzz-$libs_ver.tar.xz
libs_sha=77e4f7f98f3d86bf8788b53e6832fb96279956e1c3961988ea3d4b7ca41ddc27
libs_dep=(freetype)

libs_args=(
    -Dfreetype=enabled
    -Dglib=disabled         # for Pango
    -Dgobject=disabled      # for GNOME
    -Dgraphite2=disabled    # for texlive or LibreOffice
    -Dcairo=disabled        # optional
    -Dchafa=disabled        # optional
    -Dtests=disabled
    -Ddocs=disabled
)

is_darwin && libs_args+=(-Dcoretext=enabled)

libs_build() {
    meson setup build &&

    meson compile -C build --verbose &&
    
    pkgfile libharfbuzz -- meson install -C build --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
