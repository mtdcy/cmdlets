# A Portable Foreign Function Interface Library

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=3.7.1
libs_url=https://github.com/libffi/libffi/releases/download/v$libs_ver/libffi-$libs_ver.tar.gz
libs_sha=d5e9a6638ddbd2513ddb54518eb67e4bbe6fa707bcc01c10f6212f0a088d819d
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
