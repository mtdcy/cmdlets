# Vector graphics library with cross-device output support

# shellcheck disable=SC2034
libs_lic="LGPLv2.1,MPLv1.1"
libs_ver=1.18.4
libs_url=https://cairographics.org/releases/cairo-1.18.4.tar.xz
libs_sha=445ed8208a6e4823de1226a74ca319d3600e83f6369f99b14265006599c32ccb
libs_dep=( zlib glib libpng freetype fontconfig pixman )

libs_args=(
    -Dxlib=disabled     # without X windows
    -Dquartz=disabled   # without Quartz

    -Dtests=disabled    # without tests
)

for x in "${libs_dep[@]}"; do
    case "$x" in
        zlib       ) libs_args+=( -Dzlib=enabled       ) ;;
        glib       ) libs_args+=( -Dglib=enabled       ) ;; # libcairo-gobject.a
        libpng     ) libs_args+=( -Dpng=enabled        ) ;;
        freetype   ) libs_args+=( -Dfreetype=enabled   ) ;;
        fontconfig ) libs_args+=( -Dfontconfig=enabled ) ;;
    esac
done

libs_build() {

    meson.setup

    meson.compile

    pkgfile libcairo -- meson.install --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
