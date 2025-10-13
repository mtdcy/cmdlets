
# shellcheck disable=SC2034
libs_desc="HTTP/2 C Library"
libs_lic="MIT"
libs_ver=1.65.0
libs_url=https://github.com/nghttp2/nghttp2/releases/download/v$libs_ver/nghttp2-$libs_ver.tar.gz
libs_sha=8ca4f2a77ba7aac20aca3e3517a2c96cfcf7c6b064ab7d4a0809e7e4e9eb9914
libs_dep=()

libs_args=(
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

libs_build() {
    configure  &&

    make -C lib V=1 &&

    #make -C lib install
    library libnghttp2 \
            include/nghttp2 lib/includes/nghttp2/*.h \
            lib             lib/.libs/libnghttp2.{a,la} \
            lib/pkgconfig   lib/libnghttp2.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
