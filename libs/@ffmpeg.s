# common settings for ffmpeg

# shellcheck disable=SC2034,SC2154
FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,hwaccels,huge,ffplay}"

libs_dep=(
    # basic libs
    zlib bzip2 xz libiconv
    # audio libs
    soxr lame ogg vorbis opus
    # image libs
    png giflib turbojpeg tiff webp openjpeg
    # video libs
    #zimg 
    theora vpx
    openh264 kvazaar
    # text libs
    fribidi libass
    # demuxers & muxers
    libxml2
    # filters
    freetype fribidi harfbuzz    # for drawtext, TODO: fontconfig
)

libs_args=(
    --enable-pic
    --enable-pthreads
    --enable-hardcoded-tables
    --extra-version=cmdlets

    # toolchain
    --cc="'$CC'"
    --cxx="'$CXX'"
    --objcc="'$CC'"
    --host_ldflags="'$LDFLAGS'"

    # use extra- to avoid override default flags
    --extra-cflags="'$CFLAGS'"
    --extra-cxxflags="'$CXXFLAGS'"
    --extra-ldflags="'$LDFLAGS'"

    #--disable-stripping        # result in larger size
    #--enable-shared
    #--enable-rpath
    --enable-zlib
    --enable-bzlib
    --enable-lzma
    --enable-iconv --extra-libs=-liconv
    #--enable-libzimg
    --enable-ffmpeg
    --enable-ffprobe
    --disable-autodetect        # manual control external libraries
    --disable-htmlpages
    --enable-libsoxr            # audio resampling
    --enable-libmp3lame         # mp3 encoding
    --enable-libvpx             # vp8 & vp9 encoding & decoding
    --enable-libwebp            # webp encoding
    --enable-libvorbis          # vorbis encoding & decoding, ffmpg has native one but experimental
    --enable-libtheora          # enable if you need theora encoding
    --enable-libopus            # opus encoding & decoding, ffmpeg has native one
    --enable-libopenjpeg        # jpeg 2000 encoding & decoding, ffmpeg has native one
    --enable-libopenh264        # h264 encoding
    --enable-libkvazaar         # hevc encoding
    --enable-libass             # ass subtitles
    # for drawtext filter
    #--enable-libfontconfig
    --enable-libfreetype
    --enable-libfribidi
    --enable-libharfbuzz

    # static linked
    --disable-shared
    --enable-static
    --pkg-config="'$PKG_CONFIG'"
)

# Fix: libstdc++.a: linker input file unused because linking not done
is_darwin || {
    libs_args+=( --extra-libs=-lstdc++ )
    export LDFLAGS+=" -static-libstdc++"
}

is_darwin || {
    libs_dep+=(openssl)
    libs_args+=(
        # ffmpeg prefer shared libs, fix bug using extra libs
        #--extra-libs=\"-lm -lpthread\"
        --enable-openssl            # TLS
    )

    # TODO: Fix build libdrm with alpine/musl
    is_glibc && {
        libs_dep+=(libdrm)
        libs_args+=( --enable-libdrm )
    }
}

# always enable hwaccels for macOS
is_darwin && {
    libs_args+=(
        --enable-hwaccels
        --enable-securetransport    # TLS
        --enable-coreimage          # for avfilter
        --enable-audiotoolbox       # audio codecs
        --enable-videotoolbox       # video codecs
        --enable-opencl
    )
}

is_msys && {
    libs_args+=(
        --extra-cflags=-DKVZ_STATIC_LIB # read kvazaar's README
    )
}

libs_lic="BSD"
for v in ${FFMPEG_VARS//,/ }; do
    case "$v" in
        gpl)
            libs_lic="GPL-2.0-and-later"
            libs_dep+=(amr x264 xvidcore frei0r)
            libs_args+=(
                --enable-gpl                # GPL 2.x
                --enable-libx264            # h264 encoding
                --enable-libxvid            # mpeg4 encoding, ffmpeg has native one
                --enable-frei0r             # frei0r
            )
            # FIXME: have trouble with libx265 in macOS
            is_darwin || {
                libs_dep+=( x265 )
                libs_args+=( --enable-libx265 )
            }
            ;;
        lgpl)
            libs_lic="LGPL-3.0-and-later"
            libs_args+=(
                --enable-version3           # LGPL 3.0
                --enable-libopencore-amrnb  # amrnb encoding
                --enable-libopencore-amrwb  # amrwb encoding
            )
            ;;
        nonfree)
            # nonfree -> unredistributable
            libs_dep+=(fdk-aac)
            libs_args+=(
                --enable-nonfree
                --enable-libfdk-aac         # aac encoding
            )
            ;;
        hwaccels)
            # platform hw accel
            # https://trac.ffmpeg.org/wiki/HWAccelIntro
            libs_args+=(--enable-hwaccels)

            is_darwin || libs_dep+=(libva OpenCL)

            is_linux && libs_args+=(
                #--enable-opencl
                #--enable-opengl
                #--enable-vdpau
                --enable-vaapi
            )
            is_msys && libs_args+=(
                --enable-opencl
                --enable-d3d11va
                --enable-dxva2
            )
            ;;
        ffplay)
            libs_dep+=(sdl2)
            libs_args+=(
                --enable-ffplay
                --enable-sdl2
                --enable-outdevs
            )
            ;;
        huge)
            # custom your own build here
            libs_args+=(
                --enable-demuxers
                --enable-muxers
                --enable-decoders
                --enable-encoders
                --enable-protocols
                --enable-parsers
                --enable-bsfs
                --enable-filters
                --enable-indevs
                # no outdev here
            )
            ;;
    esac
done

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
