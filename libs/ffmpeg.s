# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=9.0.2
libs_rev=1
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,hwaccels,huge,ffplay}"

. libs/ffmpeg/common.s

libs_build() {
    #if version.ge 7.1.3; then
    #    # bug since 7.1.3, see libavcodec/vlc.c:530
    #    # https://git.ffmpeg.org/gitweb/ffmpeg.git/commitdiff/d8ffec5bf9a2803f55cc0822a97b7815f24bee83
    #    sed -i 's/av_malloc(/av_mallocz(/' libavcodec/tableprint_vlc.h
    #fi

    case "$LIBS_TARGET" in
        linux)
            # glibc 2.31 还残留着 sysctl 符号
            sed -i '/sysctl/d' configure
            ;;
    esac

    CC_C='' configure || {
        cat ffbuild/config.log >> "$_LOGFILE" &&
            die "configure ffmpeg failed."
    }

    # no docs
    sed -i Makefile \
        -e '/doc\/Makefile/d' \
        -e '/doc\/examples\/Makefile/d'

    make

    # support install seperate libraries
    sed -i ffbuild/common.mak \
        -e '/^FFLIBS /{
                s/:=/=/;
                s/\$(FFLIBS)//;
            }'

    # skip unneeded files
    sed -i Makefile \
        -e '/tools\/Makefile/d' \
        -e '/fftools\/Makefile/d' \
        -e '/tests\/Makefile/d'

    for x in avutil avcodec avformat swscale swresample avfilter avdevice; do
        cmdlet.pkgfile "lib$x" -- make install FFLIBS="$x"
    done

    # install tools
    cmdlet.install ffmpeg
    cmdlet.install ffprobe
    test -f ffplay && cmdlet.install ffplay

    # hwaccels embedded inside h264 decoder, search for "Supported hardware devices:"
    cmdlet.verify -- ffmpeg -hide_banner -h decoder=h264

    is_xbuild || cmdlet.caveats << EOF
static build ffmpeg @ $libs_ver

$(ffmpeg -hide_banner -hwaccels)

Hardware acceleration methods:

    # list hwaccels
    ffmpeg -hide_banner -hwaccels

    # vaapi (Linux)
    ffmpeg -hide_banner -codecs | grep vaapi

    # videotoolbox (macOS)
    ffmpeg -hide_banner -codecs | grep videotoolbox

    # opencl
    sudo apt install clinfo pocl-opencl-icd
    ffmpeg -hide_banner -v debug -init_hw_device opencl 2>&1 | grep "OpenCL platforms found." || echo -e "OpenCL init failed."
EOF

}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
