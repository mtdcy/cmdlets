# Simple .INI file parser in C, good for embedded systems

# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=62
libs_url=https://github.com/benhoyt/inih/archive/refs/tags/r$libs_ver.tar.gz
libs_sha=9c15fa751bb8093d042dae1b9f125eb45198c32c6704cd5481ccde460d4f8151

libs_deps=( )

# configure args
libs_args=(
    -Dcpp_std=c++11
)

libs_build() {
    meson.setup

    meson.compile

    pkgfile libinih -- meson.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
