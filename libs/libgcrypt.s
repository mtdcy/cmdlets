# Cryptographic library based on the code from GnuPG
#
# shellcheck disable=SC2034
libs_ver=1.12.0
libs_url=https://github.com/gpg/libgcrypt/archive/refs/tags/libgcrypt-$libs_ver.tar.gz
libs_sha=2e50b8fff17f35866cbca9d254c0bcec51baac5efba85c797c749c76b82aae75
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
