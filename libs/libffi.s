# A Portable Foreign Function Interface Library

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=3.5.2
libs_url=https://github.com/libffi/libffi/releases/download/v$libs_ver/libffi-$libs_ver.tar.gz
libs_sha=f3a3082a23b37c293a4fcd1053147b371f2ff91fa7ea1b2a52e335676bac82dc
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-pic
    --enable-portable-binary

    --disable-debug
    --disable-docs
    --disable-man

    # static
    --disable-shared
    --enable-static
)

is_mingw && libs_args+=( --disable-symvers )

libs_build() {

    configure

    make

    pkgfile libffi -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
