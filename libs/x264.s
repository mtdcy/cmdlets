# H.264/AVC encoder

# shellcheck disable=SC2034
# version refer: https://artifacts.videolan.org/x264/release-macos-arm64/
libs_ver=3222
libs_url=https://code.videolan.org/videolan/x264/-/archive/stable/x264-b35605a.tar.bz2
libs_sha=c28a4273ba87ddb5ceb3b6397554bd0c0e68e6484434e41467673ac80b7f7f19

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # no external libraries
    --disable-avs
    --disable-swscale
    --disable-lavf
    --disable-ffms
    --disable-gpac
    --disable-lsmash

    --enable-pic

    --disable-opencl

    # static only
    --disable-shared
    --enable-static
)

# arm64: build fail with asm
is_arm64 && libs_args+=( --disable-asm )

libs_build() {
    # old versions use yasm, but newer version use nasm
    is_arm64 || export AS="$NASM"

    configure && make &&

    pkgfile libx264 -- make install-lib-static &&

    cmdlet ./x264 &&

    check x264 -V
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
