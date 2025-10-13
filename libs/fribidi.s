# LGPL 2.1
# for libass
#
# shellcheck disable=SC2034

libs_lic=LGPL
libs_ver=1.0.5
libs_url=https://github.com/fribidi/fribidi/releases/download/v$libs_ver/fribidi-$libs_ver.tar.bz2
libs_sha=6a64f2a687f5c4f203a46fa659f43dd43d1f8b845df8d723107e8a7e6158e4ce

libs_args=(
    --enable-shared
    --enable-static
    --disable-shared 
)

libs_build() {
    configure &&

    make &&

    library fribidi \
       include/fribidi lib/fribidi*.h \
       lib lib/.libs/*.a \
       lib/pkgconfig *.pc &&

    cmdlet bin/fribidi &&

    check fribidi &&

    echo "a _lsimple _RteST_o th_oat" > test.input &&
    output=$($PREFIX/bin/fribidi --charset=CapRTL --test test.input)

    echo $output

    [ "${output#*=> }" = "a simple TSet that" ]
    return $?
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
