# GNOME XML library

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.15.1
libs_url=https://download.gnome.org/sources/libxml2/2.15/libxml2-${libs_ver}.tar.xz
libs_sha=c008bac08fd5c7b4a87f7b8a71f283fa581d80d80ff8d2efd3b26224c39bc54c
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

    # fix xml2-config
    #  1. no dynamic support, some program test with help message
    sed -i xml2-config \
        -e '/ --dynamic /d'

    pkgfile libxml2 -- make.install bin_PROGRAMS=

    for x in xmllint xmlcatalog; do
        cmdlet.install "$x"
    done

    cmdlet.check xmllint
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
