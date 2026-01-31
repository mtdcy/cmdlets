# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=4.4.6
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=2290461f467c08ab801731ed412d8e724a5511d6c33173654bd9c1d2e25d0617

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,huge}"

. libs/ffmpeg/common.s

# Unknown option "--enable-libharfbuzz".
libs_args=(${libs_args[@]//--enable-libharfbuzz/})

libs_build() {
    configure

    make ffmpeg ffprobe

    # install libs and headers only for the newest version
    cmdlet ffmpeg_g  ffmpeg${libs_ver%%.*}
    cmdlet ffprobe_g ffprobe${libs_ver%%.*}
    # install-progs will install docs, which is not needed.

    check ffmpeg${libs_ver%%.*} -version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
