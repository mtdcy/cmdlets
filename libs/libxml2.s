# GNOME XML library

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.13.9
libs_url=https://download.gnome.org/sources/libxml2/2.13/libxml2-${libs_ver}.tar.xz
libs_sha=a2c9ae7b770da34860050c309f903221c67830c86e4a7e760692b803df95143a
libs_dep=(zlib xz libiconv readline)

libs_args=(
    # avoid hardcode PREFIX
    -Dsysconfdir=/etc/
    -Dlocalstatedir=/var

    -Dzlib=enabled
    -Dlzma=enabled
    -Diconv=enabled
    -Dreadline=true
    -Dhtml=true
    -Dhttp=true
    -Dhistory=true          # history support for shell

    -Ddebuging=false
    -Dpython=false          # python bindings

    # icu: no i18n for static linked executables
    -Dicu=disabled

    # https://gitlab.gnome.org/GNOME/libxml2/-/issues/751#note_2157870
    -Dlegacy=true   # ISO-8859-X support if no iconv
)

libs_build() {
    mkdir -p build
    
    meson setup build                                      &&

    meson compile -C build --verbose                       &&

    pkgfile libxml2 -- meson install -C build --tags devel &&

    cmdlet ./build/xmllint                                 &&
    cmdlet ./build/xmlcatalog                              &&

    check xmllint --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
