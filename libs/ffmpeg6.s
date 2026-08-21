# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=6.1.6
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=d4fcb164028dd3beee5d92c0ac72e46aac6973c75ea12dc14de07bf8f407370a

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,huge}"

. libs/ffmpeg/common.s

libs_build() {
    configure

    make ffmpeg ffprobe

    ffmpeg_install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
