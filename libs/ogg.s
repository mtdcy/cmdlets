# BSD-3-Clause
#
# shellcheck disable=SC2034

libs_lic="BSD"
libs_ver=1.3.6
libs_url=https://downloads.xiph.org/releases/ogg/libogg-$libs_ver.tar.gz
libs_sha=83e6704730683d004d20e21b8f7f55dcb3383cdf84c0daedf30bde175f774638

libs_args=(
    -DBUILD_SHARED_LIBS=FALSE
)

libs_build() {
    # it seems ogg configure on every make command 

    cmake -S . -B build &&

    make -C build &&

    library ogg \
            include/ogg     include/ogg/*.h build/include/ogg/*.h \
            lib             build/*.a \
            lib/pkgconfig   build/*.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
