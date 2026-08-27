# Cryptographic library based on the code from GnuPG
#
# shellcheck disable=SC2034
libs_ver=1.12.3
libs_rev=1
libs_url=https://github.com/gpg/libgcrypt/archive/refs/tags/libgcrypt-$libs_ver.tar.gz
libs_rev=1
libs_sha=4c8878f8cd4617af6dc56e2aaa99b6d69acf2e73db68ecdfefa2c7e7ce3e31db
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
