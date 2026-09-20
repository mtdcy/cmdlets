# common settings for ffmpeg

# shellcheck disable=SC2034,SC2154
FFMPEG_VARS="${FFMPEG_VARS:-gpl,lgpl,nonfree,hwaccels,huge,ffplay}"

# ffmpeg did not handle static libraries well.
FFMPEG_ELIBS=()

libs_deps+=(
    # basic libs
    zlib bzip2 xz libiconv
    # audio libs
    soxr lame libogg libvorbis opus
    # image libs
    libpng giflib libjpeg-turbo libtiff libwebp openjpeg
    # video libs
    #zimg
    libtheora libvpx
    openh264 kvazaar
    # text libs
    libass
    # demuxers & muxers
    libxml2
    # filters
    freetype fontconfig fribidi
    # ssl
    openssl
)

libs_args+=(
    --enable-pic
    --enable-hardcoded-tables
    --extra-version=static

    # toolchain
    --cc="'$CC'"
    --cxx="'$CXX'"
    --objcc="'$CC'"

    # use extra- to avoid override default flags
    --extra-cflags="'$CFLAGS'"
    --extra-cxxflags="'$CXXFLAGS'"
    --extra-ldflags="'$LDFLAGS'"

    #--disable-stripping        # result in larger size
    #--enable-shared
)

if is_xbuild; then
    libs_args+=(
        --enable-cross-compile
        --host-cc="$HOSTCC"
    )
fi

case "$LIBS_TARGET" in
    windows)    libs_args+=(--target-os=mingw32) ;;
    cygwin)     libs_args+=(--target-os=cygwin)  ;;
    darwin)     libs_args+=(--target-os=darwin)  ;;
    *)          libs_args+=(--target-os=linux)   ;;
esac

# pthreads or winpthread(mingw/win32)
libs_args+=(--enable-pthreads)
is_mingw && is_posix && libs_args+=(--disable-w32threads)

libs_args+=(
    --enable-zlib
    --enable-bzlib
    --enable-lzma
    --enable-iconv
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

    # static linked
    --disable-shared
    --enable-static
    --pkg-config="'$PKG_CONFIG'"
)

# for drawtext filter
list_has libs_deps freetype   && libs_args+=(--enable-libfreetype)   || true # 解析字体文件并将其绘制成像素
list_has libs_deps fontconfig && libs_args+=(--enable-libfontconfig) || true # 管理并寻找合适的字体
list_has libs_deps fribidi    && libs_args+=(--enable-libfribidi)    || true # 处理 RTL 文字的正确显示顺序

list_has libs_deps openssl    && libs_args+=(--enable-openssl)

#if version.ge 6.0.0; then
#    libs_deps+=(harfbuzz)
#    libs_args+=(--enable-libharfbuzz)
#fi
case "$LIBS_TARGET" in
    darwin)
        # always enable hwaccels for macOS
        libs_args+=(
            --enable-hwaccels
            --enable-securetransport # TLS
            --enable-coreimage      # for avfilter
            --enable-audiotoolbox   # audio codecs
            --enable-videotoolbox   # video codecs
        )
        ;;
    linux)
        libs_deps+=(libdrm)
        libs_args+=(--enable-libdrm)
        ;;
esac

is_arm64 && libs_args+=(--enable-neon)

libs_lic="BSD"
for v in ${FFMPEG_VARS//,/ }; do
    case "$v" in
        gpl)
            libs_lic="GPLv2.0+"
            libs_deps+=(amr x264 xvidcore frei0r)
            libs_args+=(
                --enable-gpl                # GPL 2.x
                --enable-libx264            # h264 encoding
                --enable-libxvid            # mpeg4 encoding, ffmpeg has native one
                --enable-frei0r             # frei0r
            )
            # FIXME: have trouble with libx265 in macOS
            is_darwin || {
                libs_deps+=(x265)
                libs_args+=(--enable-libx265)
            }
            ;;
        lgpl)
            libs_lic="LGPLv3.0+"
            libs_args+=(
                --enable-version3           # LGPL 3.0
                --enable-libopencore-amrnb  # amrnb encoding
                --enable-libopencore-amrwb  # amrwb encoding
            )
            ;;
        nonfree)
            # nonfree -> unredistributable
            libs_deps+=(fdk-aac)
            libs_args+=(
                --enable-nonfree
                --enable-libfdk-aac         # aac encoding
            )
            ;;
        hwaccels)
            # platform hwaccels
            # https://trac.ffmpeg.org/wiki/HWAccelIntro
            libs_args+=(--enable-hwaccels)

            case "$LIBS_TARGET" in
                linux)
                    # VAAPI by Intel, support Linux & Intel|AMD(UVD/VCE)
                    libs_deps+=(libva)
                    libs_args+=(--enable-vaapi)
                    ;;
                windows | cygwin)
                    # DXVA2 by Microsoft, support Windows & Intel|AMD|NVIDIA
                    libs_args+=(--enable-dxva2)
                    ;;
            esac

            # always enable hwaccels for darwin

            # opencl for all
            #  musl-gcc built ffmpeg with opencl won't work on glibc platforms
            #   as dlopen system libraries will fails
            libs_args+=(--enable-opencl)
            is_darwin || libs_deps+=(OpenCL) # use OpenCL.framework for darwin

            # TODO: Vulkan
            ;;
        ffplay)
            if is_cygwin || is_mingw; then
                slogw "no ffplay for cygwin|mingw"
            else
                libs_deps+=(sdl2)
                libs_args+=(
                    --enable-ffplay
                    --enable-sdl2
                    --enable-outdevs
                )
            fi
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
                # no indevs nor outdevs here
            )
            ;;
    esac
done

# no indevs nor outdevs by default
[[ " ${libs_args[*]} " =~ " --enable-indevs " ]]  || libs_args+=(--disable-indevs)
[[ " ${libs_args[*]} " =~ " --enable-outdevs " ]] || libs_args+=(--disable-outdevs)

test -z "${FFMPEG_ELIBS[*]}" || libs_args+=(--extra-libs="'$( $PKG_CONFIG --libs-only-l "${FFMPEG_ELIBS[@]}")'")

# install libs and headers only for the newest version
ffmpeg_install() {
    local version=${libs_ver%.*}

    cmdlet.install ffmpeg_g "ffmpeg@$version"
    cmdlet.install ffprobe_g "ffprobe@$version"

    cmdlet.verify -- "ffmpeg@$version" -version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
