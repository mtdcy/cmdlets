# Library to render SVG files using Cairo

# shellcheck disable=SC2034
libs_lic="LGPLv2.1+"
libs_ver=2.61.3
libs_url=https://download.gnome.org/sources/librsvg/2.61/librsvg-2.61.3.tar.xz
libs_sha=a56d2c80d744ad2f2718f85df466fe71d24ff1f9bc3e5ef588bde4d7e87815f2
libs_dep=( glib gdk-pixbuf cairo harfbuzz freetype fontconfig pango libpng libxml2 )

# configure args
libs_args=(
    -Dpixbuf=enabled            # GDK-Pixbuf, depends on glib and gdk-pixbuf
    -Dpixbuf-loader=disabled    # needs gdk-pixbuf-query-loaders

    -Drsvg-convert=disabled

    -Ddocs=disabled
    -Dtests=False
)

libs_build() {
    cargo.requires cargo-c

    meson.setup

    # hack: something went wrong with meson+rustc build system
    if [[ "$CARGO_BUILD_TARGET" =~ -linux-musl$ ]]; then
        mkdir -p target
        ln -sfv "$(uname -m)-unknown-linux-musl" "target/$(uname -m)-unknown-linux-gnu"
    fi

    meson.compile

    pkgfile librsvg -- meson.install --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
