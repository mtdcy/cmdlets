# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=7.1.5
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=de668509caf9e35e3cd162473441fdb29538c6d96ed080292b3cf9e6fc5d558f

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,huge}"

. libs/ffmpeg/common.s

libs_build() {
    # bug since 7.1.3, see libavcodec/vlc.c:530
    # https://git.ffmpeg.org/gitweb/ffmpeg.git/commitdiff/d8ffec5bf9a2803f55cc0822a97b7815f24bee83
    sed -i 's/av_malloc(/av_mallocz(/' libavcodec/tableprint_vlc.h

    CC_C='' configure

    make ffmpeg ffprobe

    ffmpeg_install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
