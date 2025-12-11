# Cryptographic library based on the code from GnuPG
#
# shellcheck disable=SC2034
libs_ver=1.57
libs_url=https://github.com/gpg/libgpg-error/archive/refs/tags/libgpg-error-$libs_ver.tar.gz
libs_sha=69da3bd33efb87a295934c5080b3c51d55fe58c7b0d2b106d8a75da7372851ce
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
