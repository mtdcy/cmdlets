# Cryptographic library based on the code from GnuPG
#
# shellcheck disable=SC2034
libs_ver=1.58
libs_url=https://github.com/gpg/libgpg-error/archive/refs/tags/libgpg-error-$libs_ver.tar.gz
libs_sha=ccf0dfe0c782670a1604da1f39631e518cb0d0949bf7b15a491687f6ab7d7b21
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

    pkgfile "$libs_name" -- make install bin_PROGRAMS=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
