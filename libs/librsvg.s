# Library to render SVG files using Cairo

# shellcheck disable=SC2034
libs_lic="LGPLv2.1+"
libs_ver=2.61.4
libs_rev=1
libs_url=https://download.gnome.org/sources/librsvg/2.61/librsvg-2.61.4.tar.xz
libs_sha=fca0ea28d1f28f95c8407d2579f4702dac085e7c758644daca8b40d1e072ca0c
libs_dep=(glib gdk-pixbuf cairo freetype fontconfig pango libpng libxml2)

# configure args
libs_args=(
    -Dpixbuf=enabled            # GDK-Pixbuf, depends on glib and gdk-pixbuf
    -Dpixbuf-loader=disabled    # needs gdk-pixbuf-query-loaders

    -Drsvg-convert=disabled

    -Ddocs=disabled
    -Dtests=False
)

libs_build() {
    # package `cargo-c 0.10.24+cargo-0.98.0` requires rustc 1.95 or newer
    cargo.requires.rustc 1.95
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
