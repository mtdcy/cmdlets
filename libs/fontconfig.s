# XML-based font configuration API for X Windows

# refer to: https://aur.archlinux.org/packages/fontconfig-ubuntu
# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=2.18.3
libs_rev=1
libs_url=(
    https://github.com/sailfishos-mirror/fontconfig/archive/refs/tags/$libs_ver.tar.gz
    #https://gitlab.freedesktop.org/fontconfig/fontconfig/-/archive/$libs_ver/fontconfig-$libs_ver.tar.gz
)
libs_sha=9ae01e1d53acdef56010c5451cd34aa41d325b2faccd8606448d8fa01b2496b3

libs_deps=(freetype libxml2)

# XXX: meson compile fails with clang (zig cc)
# configure args
libs_args=(
    # static only
    --enable-static --disable-shared

    # libxml2 vs expat
    --enable-libxml2

    --disable-nls
    --disable-docs
    --disable-docbook
    --disable-cache-build
)

list_has libs_deps libiconv && libs_args+=(--enable-iconv) || libs_args+=(--disable-iconv)

# Cannot use default dirs on macOS due to fc-cache recursing unnecessary directories
# Issue ref: https://gitlab.freedesktop.org/fontconfig/fontconfig/-/work_items/547
is_darwin && libs_args+=(--with-default-fonts-dirs="/System/Library/Fonts,/Library/Fonts,~/Library/Fonts")

libs_build() {
    slogcmd autoreconf -fiv

    configure

    make

    cmdlet.pkgfile libfontconfig -- make install SUBDIRS="fontconfig src"

    # tools
    for x in fc-list fc-scan fc-query fc-validate; do
        cmdlet.install "$x/$x" "$x"
    done

    cmdlet.verify -- fc-list --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
