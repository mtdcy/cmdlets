# C string library for manipulating Unicode strings
#
# shellcheck disable=SC2034
libs_lic='LGPLv3+|GPLv2'
libs_ver=1.4.1
libs_url=https://ftpmirror.gnu.org/gnu/libunistring/libunistring-$libs_ver.tar.gz
libs_sha=12542ad7619470efd95a623174dcd4b364f2483caf708c6bee837cb53a54cb9d
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
