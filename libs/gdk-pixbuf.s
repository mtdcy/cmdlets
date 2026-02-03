# Toolkit for image loading and pixel buffer manipulation

# shellcheck disable=SC2034
libs_lic="LGPLv2.1+"
libs_ver=2.44.5
libs_url=https://download.gnome.org/sources/gdk-pixbuf/2.44/gdk-pixbuf-2.44.5.tar.xz
libs_sha=69b93e09139b80c0ee661503d60deb5a5874a31772b5184b9cd5462a4100ab68
libs_dep=( glib libjpeg-turbo libpng libtiff )

# configure args
libs_args=(
    -Drelocatable=false
    -Dnative_windows_loaders=false

    -Dbuiltin_loaders=all

    # use same sniff for all platforms: gdk-pixbuf-io.c:format_check
    -Dgio_sniffing=false

    -Dothers=disabled           # other loaders are weakly maintained
    -Dglycin=disabled

    -Dman=false
    -Dtests=false
    -Ddocumentation=false
    -Dinstalled_tests=false
)

for x in "${libs_dep[@]}"; do
    case "$x" in
        libpng        ) libs_args+=( -Dpng=enabled  ) ;;
        libtiff       ) libs_args+=( -Dtiff=enabled ) ;;
        libjpeg-turbo ) libs_args+=( -Djpeg=enabled ) ;;
    esac
done

libs_build() {
    meson.setup

    meson.compile

    pkgfile libgdk-pixbuf -- meson.install --tags devel

    #cmdlet.install ./build/gdk-pixbuf/gdk-pixbuf-query-loaders
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
