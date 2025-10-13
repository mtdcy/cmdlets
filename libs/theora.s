
#
# shellcheck disable=SC2034

upkg_lic="BSD-3-Clause"
upkg_ver=1.1.1
upkg_url=https://downloads.xiph.org/releases/theora/libtheora-$upkg_ver.tar.bz2
upkg_sha=b6ae1ee2fa3d42ac489287d3ec34c5885730b1296f0801ae577a35193d3affbc
upkg_dep=(ogg vorbis)

upkg_args=(
    --disable-examples
    --disable-oggtest
    --disable-vorbistest
    --with-ogg=$PREFIX
    --with-vorbis=$PREFIX
    --disable-shared
    --enable-static
    )

# fix 'error: cannot guess build type'
is_darwin || upkg_args+=( --build="$(uname -m)-unknown-linux-gnu" )

upkg_static() {
    configure && 

    make && 

    make check &&
    
    library theora \
        include/theora include/theora/*.h \
        lib lib/.libs/*.a \
        lib/pkgconfig theora*.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
