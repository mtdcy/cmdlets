# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=7.1.3
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=f0bf043299db9e3caacb435a712fc541fbb07df613c4b893e8b77e67baf3adbe

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,huge}"

. libs/ffmpeg/common.s

libs_build() {
    # bug since 7.1.3, see libavcodec/vlc.c:530
    # https://git.ffmpeg.org/gitweb/ffmpeg.git/commitdiff/d8ffec5bf9a2803f55cc0822a97b7815f24bee83
    sed -i 's/av_malloc(/av_mallocz(/' libavcodec/tableprint_vlc.h

	CC_C='' configure

    make ffmpeg ffprobe

    # install libs and headers only for the newest version
    cmdlet.install ffmpeg_g  "ffmpeg${libs_ver%%.*}"
    cmdlet.install ffprobe_g "ffprobe${libs_ver%%.*}"
    # install-progs will install docs, which is not needed.

    cmdlet.check "ffmpeg${libs_ver%%.*}" -version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
