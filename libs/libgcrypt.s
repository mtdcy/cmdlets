# Cryptographic library based on the code from GnuPG
#
# shellcheck disable=SC2034
libs_ver=1.12.2
libs_url=https://github.com/gpg/libgcrypt/archive/refs/tags/libgcrypt-$libs_ver.tar.gz
libs_sha=3506339b02adb6148fa2365a4e748f3d30fcc351b8c443897cd0d6fbcd4cfaf8
libs_dep=( libxml2 libgpg-error )

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --disable-doc

    # static only
    --disable-shared
    --enable-static
)
    
is_arm64 && libs_args+=( --disable-asm )

libs_build() {
    configure

    make

    pkgfile "$libs_name" -- make install bin_PROGRAMS=

    cmdlet.install src/hmac256
    cmdlet.install src/dumpsexp
    cmdlet.install src/mpicalc

    cmdlet.check hmac256
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
