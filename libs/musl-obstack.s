# A standalone library to implement GNU libc's obstack
#
# shellcheck disable=SC2034
libs_ver=1.2.3
libs_url=https://github.com/void-linux/musl-obstack/archive/refs/tags/v1.2.3.tar.gz
libs_sha=9ffb3479b15df0170eba4480e51723c3961dbe0b461ec289744622db03a69395
libs_dep=( )

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    # static only
    --disable-shared
    --enable-static
)

libs_build() {

    configure

    make.all

    pkgfile libobstack -- make.install
}

libs_depends is_musl

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
