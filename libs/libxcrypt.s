# Extended crypt library for descrypt, md5crypt, bcrypt, and others
#
# shellcheck disable=SC2034
libs_lic="LGPL-2.1-or-later"
libs_ver=4.4.38
libs_url=https://github.com/besser82/libxcrypt/releases/download/v$libs_ver/libxcrypt-$libs_ver.tar.xz
libs_sha=80304b9c306ea799327f01d9a7549bdb28317789182631f1b54f4511b4206dd6
libs_dep=( )

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --disable-obsolete-api
    --disable-xcrypt-compat-files
    --disable-failure-tokens
    --disable-valgrind

    --with-pic

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    pkgfile libxcrypt -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
