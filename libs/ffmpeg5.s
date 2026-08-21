# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=5.1.10
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=392306d6fc45dab0e9e0ea55381e071842e83a2fb31d320aeda40477a7766293

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
