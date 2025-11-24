# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=6.1.4
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=a231e3d5742c44b1cdaebfb98ad7b6200d12763e0b6db9e1e2c5891f2c083a18

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,huge}"

# shellcheck source=@ffmpeg.s
. libs/@ffmpeg.s

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
