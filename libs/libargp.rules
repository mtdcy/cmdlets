# Standalone version of arguments parsing functions from GLIBC

# shellcheck disable=SC2034
libs_ver=1.5.0
libs_url=https://github.com/argp-standalone/argp-standalone/archive/refs/tags/1.5.0.tar.gz
libs_sha=c29eae929dfebd575c38174f2c8c315766092cec99a8f987569d0cad3c6d64f6

libs_deps=( )

# configure args
libs_args=(
    -Dcpp_std=c++11
)

libs_build() {
    sed -i '/HAVE_LIBINTL_H/d' meson.build

    meson.setup

    meson.compile

    cmdlet.pkgconf "$PREFIX/lib/pkgconfig/argp.pc" -largp

    cmdlet.pkgfile "$libs_name" lib/pkgconfig/argp.pc -- meson.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
