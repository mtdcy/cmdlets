#!/bin/bash
# XML 1.0 parser

# shellcheck disable=SC2034
libs_name=expat
libs_lic="MIT"
libs_ver=2.8.4
libs_rev=1
libs_url=https://github.com/libexpat/libexpat/releases/download/R_${libs_ver//./_}/expat-$libs_ver.tar.gz
libs_sha=b8ece2437692dad44d851c4532723390a5a330990007706be9c8d2b90d294f36
libs_dep=()

# configure args
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --without-docbook
    --without-examples
    --without-tests

    --disable-shared
    --enable-static
)

libs_build() {
    configure && make || return $?

    pkgfile libexpat -- make install SUBDIRS=lib &&

    cmdlet ./xmlwf/xmlwf
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
