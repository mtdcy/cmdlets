# C library for the Public Suffix List

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.22.0
libs_url=https://github.com/rockdaboot/libpsl/releases/download/0.22.0/libpsl-0.22.0.tar.gz
libs_sha=c45c3aa17576b99873e05a9b09a44041b065bbfa390e6d474d06fbfaeb9c7722
libs_dep=( libidn2 libunistring )

# configure args
libs_args=(
    -Druntime=libidn2
    -Dbuiltin=true
)

libs_build() {

    meson.setup

    meson.compile

    pkgfile libpsl -- meson.install --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
