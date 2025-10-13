# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=5.1.7
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=27d87965c5b0ab857a0092aeb9f55d975becb7126d83aefe39ae24102492180b

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,huge}"

# shellcheck source=@ffmpeg.u
. libs/@ffmpeg.u

# Unknown option "--enable-libharfbuzz".
libs_args=(${libs_args[@]//--enable-libharfbuzz/})

libs_build() {
    configure &&

    make ffmpeg ffprobe &&

    # install libs and headers only for the newest version
    cmdlet ffmpeg_g  ffmpeg${libs_ver%%.*} &&
    cmdlet ffprobe_g ffprobe${libs_ver%%.*} &&
    # install-progs will install docs, which is not needed.

    check ffmpeg${libs_ver%%.*} -version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
