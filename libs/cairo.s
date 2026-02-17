# Vector graphics library with cross-device output support

# shellcheck disable=SC2034
libs_lic="LGPLv2.1,MPLv1.1"
libs_ver=1.18.4
libs_url=https://cairographics.org/releases/cairo-1.18.4.tar.xz
libs_sha=445ed8208a6e4823de1226a74ca319d3600e83f6369f99b14265006599c32ccb

libs_deps=( zlib lzo glib libpng freetype fontconfig pixman )

libs_args=(
    -Dxlib=disabled     # without X windows
    -Dquartz=disabled   # without Quartz

    -Dtests=disabled    # without tests
)

is_listed zlib       libs_deps && libs_args+=( -Dzlib=enabled       ) || libs_args+=( -Dzlib=disabled       )
is_listed lzo        libs_deps && libs_args+=( -Dlzo=enabled        ) || libs_args+=( -Dlzo=disabled        )
is_listed glib       libs_deps && libs_args+=( -Dglib=enabled       ) || libs_args+=( -Dglib=disabled       )
is_listed libpng     libs_deps && libs_args+=( -Dpng=enabled        ) || libs_args+=( -Dpng=disabled        )
is_listed freetype   libs_deps && libs_args+=( -Dfreetype=enabled   ) || libs_args+=( -Dfreetype=disabled   )
is_listed fontconfig libs_deps && libs_args+=( -Dfontconfig=enabled ) || libs_args+=( -Dfontconfig=disabled )

libs_build() {

    meson.setup

    meson.compile

    # fix missing stdc++
    cmdlet.pkgconf meson-private/cairo.pc -lstdc++

    # fix missing CAIRO_WIN32_STATIC_BUILD
    is_mingw && cmdlet.pkgconf meson-private/cairo.pc -DCAIRO_WIN32_STATIC_BUILD 

    pkgfile libcairo -- meson.install --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
