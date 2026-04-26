
# shellcheck disable=SC2034
libs_desc="HTTP/2 C Library"
libs_lic="MIT"
libs_ver=1.69.0
libs_url=https://github.com/nghttp2/nghttp2/releases/download/v1.69.0/nghttp2-1.69.0.tar.gz
libs_sha=c866b7477cbb7512ab6863a685027adbb1bb8da8fc3bab7429ed43d3281d5aa9
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
