# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=8.0.1
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=05ee0b03119b45c0bdb4df654b96802e909e0a752f72e4fe3794f487229e5a41

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,hwaccels,huge,ffplay}"

. libs/ffmpeg/common.s

install_ffmpeg_libs() {
    pkgconf "$1" -l"$1"

    cmdlet.pkginst lib$1                \
        include/lib$1   lib$1/*.h       \
        lib             lib$1/lib$1.a   \
        lib/pkgconfig   $1.pc
}

libs_build() {
    if version.ge "$libs_ver" 7.1.3; then
        # bug since 7.1.3, see libavcodec/vlc.c:530
        # https://git.ffmpeg.org/gitweb/ffmpeg.git/commitdiff/d8ffec5bf9a2803f55cc0822a97b7815f24bee83
        sed -i 's/av_malloc(/av_mallocz(/' libavcodec/tableprint_vlc.h
    fi

	CC_C='' configure

	make

    # install libs headers progs
    install_ffmpeg_libs avutil
    install_ffmpeg_libs avformat
    install_ffmpeg_libs avcodec
    install_ffmpeg_libs swscale
    install_ffmpeg_libs swresample
    install_ffmpeg_libs avfilter
    install_ffmpeg_libs avdevice

    # install tools
    cmdlet.install ffmpeg
    cmdlet.install ffprobe
    cmdlet.install ffplay

    cmdlet.check ffmpeg -version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
