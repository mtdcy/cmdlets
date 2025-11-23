# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=7.1.3
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=f0bf043299db9e3caacb435a712fc541fbb07df613c4b893e8b77e67baf3adbe

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,hwaccels,huge,ffplay}"

# shellcheck source=@ffmpeg.s
. libs/@ffmpeg.s

install_ffmpeg_libs() {
    pkginst lib$1                      \
        include/lib$1   lib$1/*.h      \
        lib             lib$1/lib$1.a  \
        lib/pkgconfig   lib$1/lib$1.pc
}

libs_build() {
	CC_C='' configure  &&

	make &&

    # install libs headers progs
    install_ffmpeg_libs avutil     &&
    install_ffmpeg_libs avformat   &&
    install_ffmpeg_libs avcodec    &&
    install_ffmpeg_libs postproc   &&
    install_ffmpeg_libs swscale    &&
    install_ffmpeg_libs swresample &&
    install_ffmpeg_libs avfilter   &&
    install_ffmpeg_libs avdevice   &&
   
    # install tools 
    cmdlet ffmpeg  ffmpeg  &&
    cmdlet ffprobe ffprobe &&
    cmdlet ffplay  ffplay  &&

    check ffmpeg -version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
