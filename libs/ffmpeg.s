# Play, record, convert, and stream audio and video

# shellcheck disable=SC2034
libs_ver=8.0.1
libs_url=https://ffmpeg.org/releases/ffmpeg-$libs_ver.tar.xz
libs_sha=05ee0b03119b45c0bdb4df654b96802e909e0a752f72e4fe3794f487229e5a41

FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,hwaccels,huge,ffplay}"

. libs/ffmpeg/common.s

libs_build() {
    if version.ge 7.1.3; then
        # bug since 7.1.3, see libavcodec/vlc.c:530
        # https://git.ffmpeg.org/gitweb/ffmpeg.git/commitdiff/d8ffec5bf9a2803f55cc0822a97b7815f24bee83
        sed -i 's/av_malloc(/av_mallocz(/' libavcodec/tableprint_vlc.h
    fi

	CC_C='' configure || {
        cat ffbuild/config.log >> "$_LOGFILE" &&
        die "configure ffmpeg failed."
    }

    # no docs
    sed -i Makefile \
        -e '/doc\/Makefile/d' \
        -e '/doc\/examples\/Makefile/d' \

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
        -e '/tests\/Makefile/d' \

    for x in avutil avcodec avformat swscale swresample avfilter avdevice; do
        cmdlet.pkgfile "lib$x" -- make.install FFLIBS="$x"
    done

    # install tools
    cmdlet.install ffmpeg
    cmdlet.install ffprobe
    cmdlet.install ffplay

    cmdlet.check ffmpeg -version

    cmdlet.caveats <<EOF
static build ffmpeg @ $libs_ver

$(run ffmpeg -hide_banner -hwaccels)
EOF
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
