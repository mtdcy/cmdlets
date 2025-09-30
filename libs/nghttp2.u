
# shellcheck disable=SC2034
upkg_desc="HTTP/2 C Library"
upkg_lic="MIT"
upkg_ver=1.65.0
upkg_url=https://github.com/nghttp2/nghttp2/releases/download/v$upkg_ver/nghttp2-$upkg_ver.tar.gz
upkg_sha=8ca4f2a77ba7aac20aca3e3517a2c96cfcf7c6b064ab7d4a0809e7e4e9eb9914
upkg_dep=()

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-lib-only

    --disable-nls
    --disable-rpath

    --disable-doc
    --disable-man

    --disable-shared
    --enable-static
)

upkg_static() {
    configure  &&

    make -C lib V=1 &&

    #make -C lib install
    library libnghttp2 \
            include/nghttp2 lib/includes/nghttp2/*.h \
            lib             lib/.libs/libnghttp2.{a,la} \
            lib/pkgconfig   lib/libnghttp2.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
