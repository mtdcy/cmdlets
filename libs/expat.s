#!/bin/bash
# XML 1.0 parser

# shellcheck disable=SC2034
upkg_name=expat
upkg_lic="MIT"
upkg_ver=2.7.3
upkg_url=https://github.com/libexpat/libexpat/releases/download/R_${upkg_ver//./_}/expat-$upkg_ver.tar.gz
upkg_sha=821ac9710d2c073eaf13e1b1895a9c9aa66c1157a99635c639fbff65cdbdd732
upkg_dep=()

# configure args
upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --without-docbook
    --without-examples
    --without-tests

    --disable-shared
    --enable-static
)

upkg_static() {

    configure &&

    make &&

    library expat \
            include expat_config.h lib/expat.h lib/expat_external.h \
            lib     lib/.libs/libexpat.{a,la} \
            lib/pkgconfig expat.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
