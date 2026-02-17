# Framework for layout and rendering of i18n text

# shellcheck disable=SC2034
libs_lic="LGPLv2.0+"
libs_ver=1.57.0
libs_url=https://download.gnome.org/sources/pango/1.57/pango-1.57.0.tar.xz
libs_sha=890640c841dae77d3ae3d8fe8953784b930fa241b17423e6120c7bfdf8b891e7

libs_deps=( glib cairo freetype fribidi harfbuzz fontconfig )

libs_patches=(
    https://gitlab.gnome.org/GNOME/pango/-/commit/4403954455f2b4a815b32e11c44f79b2e665e94c.diff
)

# configure args
libs_args=(
    -Dlibthai=disabled

    -Dbuild-examples=false
    -Dbuild-testsuite=false
)

is_listed cairo      libs_deps && libs_args+=( -Dcairo=enabled      ) || libs_args+=( -Dcairo=disabled      )
is_listed freetype   libs_deps && libs_args+=( -Dfreetype=enabled   ) || libs_args+=( -Dfreetype=disabled   )
is_listed fontconfig libs_deps && libs_args+=( -Dfontconfig=enabled ) || libs_args+=( -Dfontconfig=disabled )

libs_build() {
    meson.setup

    meson.compile

    pkgfile libpango -- meson.install --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
