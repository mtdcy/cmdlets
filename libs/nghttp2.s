
# shellcheck disable=SC2034
libs_desc="HTTP/2 C Library"
libs_lic="MIT"
libs_ver=1.68.0
libs_url=https://github.com/nghttp2/nghttp2/releases/download/v1.68.0/nghttp2-1.68.0.tar.gz
libs_sha=2c16ffc588ad3f9e2613c3fad72db48ecb5ce15bc362fcc85b342e48daf51013
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

    pkgfile libnghttp2 -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
