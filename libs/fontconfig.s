# XML-based font configuration API for X Windows

# refer to: https://aur.archlinux.org/packages/fontconfig-ubuntu
# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=2.18.3
libs_url=(
    https://github.com/sailfishos-mirror/fontconfig/archive/refs/tags/$libs_ver.tar.gz
    #https://gitlab.freedesktop.org/fontconfig/fontconfig/-/archive/$libs_ver/fontconfig-$libs_ver.tar.gz
)
libs_sha=9ae01e1d53acdef56010c5451cd34aa41d325b2faccd8606448d8fa01b2496b3
libs_dep=(freetype libxml2)

# configure args
libs_args=(
    --localstatedir=/var
    --sysconfdir=/etc

    -Dxml-backend=libxml2   # lightweight expat vs libxml2

    -Dtools=enabled

    -Dnls=disabled
    -Ddoc=disabled
    -Dtests=disabled
    -Dcache-build=disabled

    # avoid hardcode PREFIX
    -Dtemplate-dir=/usr/share/fontconfig/conf.avail
    -Dxml-dir=/usr/share/xml/fontconfig
)

# not neccesary
#is_darwin && libs_args+=( -Dadditional-fonts-dirs="'/System/Library/Fonts,/Library/Fonts,~/Library/Fonts'" )

libs_build() {

    meson.setup

    meson.compile

    pkgfile libfontconfig -- meson.install --tags devel

    # tools
    for x in fc-list fc-scan fc-query fc-validate; do
        cmdlet.install "$x/$x" "$x"
    done

    cmdlet.check fc-list --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
