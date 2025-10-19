# Cryptographic library based on the code from GnuPG
#
# shellcheck disable=SC2034
libs_ver=1.11.2
libs_url=https://github.com/gpg/libgcrypt/archive/refs/tags/libgcrypt-$libs_ver.tar.gz
libs_sha=9414fcd2c9b3144c695e74e30e5054bcda440a8de4dd991a902f503cc53ccc18
libs_dep=( libxml2 libgpg-error )

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --with-pic
    --disable-asm
    --disable-doc

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    pkgfile "$libs_name" -- make install bin_PROGRAMS=

    cmdlet ./src/hmac256
    cmdlet ./src/dumpsexp
    cmdlet ./src/mpicalc

    check hmac256
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
