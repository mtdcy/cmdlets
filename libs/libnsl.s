# Public client interface for NIS(YP) and NIS+

# shellcheck disable=SC2034
libs_lic='LGPL-2.1+'
libs_ver=2.0.1
libs_url=https://github.com/thkukuk/libnsl/releases/download/v2.0.1/libnsl-2.0.1.tar.xz
libs_sha=5c9e470b232a7acd3433491ac5221b4832f0c71318618dc6aa04dd05ffcd8fd9
libs_dep=( libtirpc )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-nls
    --without-libintl-prefix

    --disable-shared
    --enable-static
)

libs_build() {

    configure

    make

    pkgfile $libs_name -- make install bin_SCRIPTS=
}

libs.depends is_linux

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
