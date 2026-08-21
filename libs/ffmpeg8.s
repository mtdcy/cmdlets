# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=8.1.2
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=464beb5e7bf0c311e68b45ae2f04e9cc2af88851abb4082231742a74d97b524c

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,huge}"

. libs/ffmpeg/common.s

libs_build() {
    # bug since 7.1.3, see libavcodec/vlc.c:530
    # https://git.ffmpeg.org/gitweb/ffmpeg.git/commitdiff/d8ffec5bf9a2803f55cc0822a97b7815f24bee83
    #sed -i 's/av_malloc(/av_mallocz(/' libavcodec/tableprint_vlc.h

    CC_C='' configure

    make ffmpeg ffprobe

    ffmpeg_install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
