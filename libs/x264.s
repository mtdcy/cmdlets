# H.264/AVC encoder

# shellcheck disable=SC2034
libs_ver=0480cb05
libs_url=https://code.videolan.org/videolan/x264/-/archive/stable/x264-$libs_ver.tar.bz2
libs_sha=c28a4273ba87ddb5ceb3b6397554bd0c0e68e6484434e41467673ac80b7f7f19

libs_args=(
    --disable-avs
    --disable-swscale
    --disable-lavf
    --disable-ffms
    --disable-gpac
    --disable-lsmash
    --extra-cflags="'$CFLAGS'"
    --extra-ldflags="'$LDFLAGS'"
    --enable-pic
    --disable-shared
    --enable-static
    )

# arm64: build fail with asm
is_arm64 && libs_args+=( --disable-asm )

libs_build() {
    # old versions use yasm, but newer version use nasm
    AS="$NASM" configure &&

    make &&

    library libx264 x264.h x264_config.h libx264.a x264.pc &&

    cmdlet x264 &&

    check x264 -V
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
