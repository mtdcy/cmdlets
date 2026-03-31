# Cryptographic library based on the code from GnuPG
#
# shellcheck disable=SC2034
libs_ver=1.59
libs_url=https://github.com/gpg/libgpg-error/archive/refs/tags/libgpg-error-$libs_ver.tar.gz
libs_sha=6f69a2eaf688a91d806142080d4a4638cf3e936647fdcaac02e93ea4daee0858
libs_dep=( )

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    # needed by some libraries, e.g: libgcrypt
    --enable-install-gpg-error-config

    --disable-nls
    --disable-doc
    --disable-tests
    --without-libintl-prefix
    --without-libiconv-prefix

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    # only gpgrt-config and always enable static
    sed -i src/gpgrt-config \
        -e '/^enable_static/s/=.*/=yes/'

    pkgfile "$libs_name" -- make install bin_PROGRAMS= bin_SCRIPTS=gpgrt-config
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
