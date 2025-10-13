# BSD-3-Clause
#
# shellcheck disable=SC2034

upkg_lic="BSD"
upkg_ver=1.3.6
upkg_url=https://downloads.xiph.org/releases/ogg/libogg-$upkg_ver.tar.gz
upkg_sha=83e6704730683d004d20e21b8f7f55dcb3383cdf84c0daedf30bde175f774638

upkg_args=(
    -DBUILD_SHARED_LIBS=FALSE
)

upkg_static() {
    # it seems ogg configure on every make command 

    cmake -S . -B build &&

    make -C build &&

    library ogg \
            include/ogg     include/ogg/*.h build/include/ogg/*.h \
            lib             build/*.a \
            lib/pkgconfig   build/*.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
