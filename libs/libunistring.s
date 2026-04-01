# C string library for manipulating Unicode strings
#
# shellcheck disable=SC2034
libs_lic='LGPLv3+|GPLv2'
libs_ver=1.4.2
libs_url=https://ftpmirror.gnu.org/gnu/libunistring/libunistring-$libs_ver.tar.gz
libs_sha=e82664b170064e62331962126b259d452d53b227bb4a93ab20040d846fec01d8
libs_dep=( libiconv )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --with-libiconv-prefix="'$PREFIX'"

    # static only
    --disable-shared
    --enable-static
)

is_mingw && libs_args+=( --enable-threads=win32 )

libs_build() {
    configure

    make

    # fails with mingw
    # FIXME: fail sometimes with musl-gcc
    ( make check ) || true

    pkgfile libunistring -- make.install SUBDIRS=lib
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
