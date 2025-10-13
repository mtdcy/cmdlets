# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=6.1.3
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=bc5f1e4a4d283a6492354684ee1124129c52293bcfc6a9169193539fbece3487

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,huge}"

# shellcheck source=@ffmpeg.u
. libs/@ffmpeg.u

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
