# XML-based font configuration API for X Windows

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=2.17.1
libs_url=https://gitlab.freedesktop.org/fontconfig/fontconfig/-/archive/2.17.1/fontconfig-2.17.1.tar.gz
libs_sha=82e73b26adad651b236e5f5d4b3074daf8ff0910188808496326bd3449e5261d
libs_dep=( freetype libxml2 )

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
        cmdlet.install "./build/$x/$x" "$x"
    done

    cmdlet.check fc-list --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
