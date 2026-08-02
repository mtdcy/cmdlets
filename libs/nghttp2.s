
# shellcheck disable=SC2034
libs_desc="HTTP/2 C Library"
libs_lic="MIT"
libs_ver=1.70.0
libs_url=https://github.com/nghttp2/nghttp2/releases/download/v1.70.0/nghttp2-1.70.0.tar.gz
libs_sha=aa317e2cf9dca6afa0aed68f8fad6ff303ec6982e25a78c75c0b65e2b9b3ded5
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-lib-only

    --disable-man

    # static
    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make -C lib V=1

    pkgconf lib/libnghttp2.pc -DNGHTTP2_STATICLIB

    pkgfile libnghttp2 -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
