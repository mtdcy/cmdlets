# GNOME XML library

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.13.9
libs_url=https://download.gnome.org/sources/libxml2/2.13/libxml2-${libs_ver}.tar.xz
libs_sha=a2c9ae7b770da34860050c309f903221c67830c86e4a7e760692b803df95143a
libs_dep=(zlib xz libiconv readline)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --sysconfdir=/etc

    --with-zlib
    --with-lzma

    --with-history # shell mode
    --with-http

    # python ?
    --without-python

    # icu4c ?
    --without-icu

    # https://gitlab.gnome.org/GNOME/libxml2/-/issues/751#note_2157870
    --with-legacy

    --disable-shared
    --enable-static
)

libs_build() {

    configure

    # no doc and examples
    sed -i Makefile \
        -e '/^SUBDIRS/s/doc example//'

    make.all

    pkgfile libxml2 -- make.install bin_PROGRAMS=

    for x in xmllint xmlcatalog; do
        cmdlet.install "$x"
    done

    cmdlet.check xmllint --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
