# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=5.1.8
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=56d4daf10c17330a45c8fe11bc260997677ca2432d3d5951dbeb5515c26028cb

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,huge}"

. libs/ffmpeg/common.s

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
