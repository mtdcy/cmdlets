#!/bin/bash
# XML 1.0 parser

# shellcheck disable=SC2034
libs_name=expat
libs_lic="MIT"
libs_ver=2.7.4
libs_url=https://github.com/libexpat/libexpat/releases/download/R_${libs_ver//./_}/expat-$libs_ver.tar.gz
libs_sha=461ecc8aa98ab1a68c2db788175665d1a4db640dc05bf0e289b6ea17122144ec
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
