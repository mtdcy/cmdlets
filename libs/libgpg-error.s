# Cryptographic library based on the code from GnuPG
#
# shellcheck disable=SC2034
libs_ver=1.60
libs_url=https://github.com/gpg/libgpg-error/archive/refs/tags/libgpg-error-$libs_ver.tar.gz
libs_sha=f30cbd5b5ebc4e858bd120ea0d942ef61bd2e9798aebc1bf9490e5a04fe3634d
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
