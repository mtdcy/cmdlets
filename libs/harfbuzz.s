# OpenType text shaping engine
#
#  1. Fontconfig → 匹配字体 (告诉系统该用哪个 .ttf 文件)
#       ↓
#  2. HarfBuzz → 字形塑形 (读取字体规则，处理连字、词尾形变，计算每个字的精确相对坐标)
#       ↓
#  3. FreeType → 最终绘制 (根据 HarfBuzz 给出的字形 ID 和坐标，把它们画成像素)

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=8.5.0
libs_url=https://github.com/harfbuzz/harfbuzz/releases/download/$libs_ver/harfbuzz-$libs_ver.tar.xz
libs_sha=77e4f7f98f3d86bf8788b53e6832fb96279956e1c3961988ea3d4b7ca41ddc27

libs_deps=(freetype)

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
    meson.setup

    meson.compile

    pkgfile libharfbuzz -- meson.install --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
