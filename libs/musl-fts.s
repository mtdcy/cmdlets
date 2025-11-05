# Implementation of fts(3) for musl libc
#
# shellcheck disable=SC2034
libs_ver=1.2.7
libs_url=https://github.com/void-linux/musl-fts/archive/refs/tags/v1.2.7.tar.gz
libs_sha=49ae567a96dbab22823d045ffebe0d6b14b9b799925e9ca9274d47d26ff482a6
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
    depends_on is_musl

    configure

    make.all

    pkgfile libfts -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
