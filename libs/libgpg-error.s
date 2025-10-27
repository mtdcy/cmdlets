# Cryptographic library based on the code from GnuPG
#
# shellcheck disable=SC2034
libs_ver=1.56
libs_url=https://github.com/gpg/libgpg-error/archive/refs/tags/libgpg-error-$libs_ver.tar.gz
libs_sha=5ab0e03f6c0f739863a3b92a42bfe0ad1264bd56ca6e3c917bd283b1ac81ab72
libs_dep=( )

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --with-pic
    --disable-nls
    --disable-doc
    --disable-tests

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    pkgfile "$libs_name" -- make install bin_PROGRAMS= bin_SCRIPTS=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
