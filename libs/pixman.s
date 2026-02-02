# Low-level library for pixel manipulation

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.46.4
libs_url=https://cairographics.org/releases/pixman-0.46.4.tar.gz
libs_sha=d09c44ebc3bd5bee7021c79f922fe8fb2fb57f7320f55e97ff9914d2346a591c
libs_dep=( )

# configure args
libs_args=(
    -Ddemos=disabled
)

libs_build() {

    meson.setup

    meson.compile

    pkgfile libpixman -- meson.install --tags devel
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
