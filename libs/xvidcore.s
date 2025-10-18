# High-performance, high-quality MPEG-4 video library

# shellcheck disable=SC2034
libs_lic="GPL-2.0-or-later"
libs_ver=1.3.7
libs_url=https://downloads.xvid.com/downloads/xvidcore-$libs_ver.tar.bz2
libs_sha=aeeaae952d4db395249839a3bd03841d6844843f5a4f84c271ff88f7aa1acff7

libs_build() {
    cd build/generic

    configure --disable-shared --enable-static &&

    make all

    pkginst xvidcore \
        include ../../src/xvid.h \
        lib =build/libxvidcore.a
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
