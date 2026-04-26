#!/bin/bash
# XML 1.0 parser

# shellcheck disable=SC2034
libs_name=expat
libs_lic="MIT"
libs_ver=2.8.0
libs_url=https://github.com/libexpat/libexpat/releases/download/R_${libs_ver//./_}/expat-$libs_ver.tar.gz
libs_sha=c7cec5f60ea3a42e7780781c6745255c19aa3dbfeeae58646b7132f88dc24780
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
