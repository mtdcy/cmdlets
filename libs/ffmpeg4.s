# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=4.4.8
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=c73848c4ae283d9eaee7be3b276affbc3543380483555500d0dd2c9b7e1c39c3

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,huge}"

. libs/ffmpeg/common.s

# Unknown option "--enable-libharfbuzz".
libs_args=(${libs_args[@]//--enable-libharfbuzz/})

libs_build() {
    configure

    make ffmpeg ffprobe

    ffmpeg_install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
