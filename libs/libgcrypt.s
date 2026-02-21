# Cryptographic library based on the code from GnuPG
#
# shellcheck disable=SC2034
libs_ver=1.12.1
libs_url=https://github.com/gpg/libgcrypt/archive/refs/tags/libgcrypt-$libs_ver.tar.gz
libs_sha=e2bb8bf1bee4c0a66f2713db9577e0bb88eaf9a31d91dbe944c26ff47e336266
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
