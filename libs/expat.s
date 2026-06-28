#!/bin/bash
# XML 1.0 parser

# shellcheck disable=SC2034
libs_name=expat
libs_lic="MIT"
libs_ver=2.8.2
libs_url=https://github.com/libexpat/libexpat/releases/download/R_${libs_ver//./_}/expat-$libs_ver.tar.gz
libs_sha=ef7d1994f533c9e7343d6c19f31064fc8ebbcbcaa144be3812b4f43052a05f4c
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
