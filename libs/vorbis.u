# BSD-3-Clause
#
# shellcheck disable=SC2034

upkg_lic="BSD"
upkg_ver=1.3.7
upkg_url=https://downloads.xiph.org/releases/vorbis/libvorbis-$upkg_ver.tar.xz
upkg_sha=b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b
upkg_dep=(ogg)

upkg_args=()

upkg_static() {
    cmake -S . -B build &&

    make -C build &&

    library vorbis \
            include/vorbis  include/vorbis/*.h \
            lib             build/lib/*.a \
            lib/pkgconfig   build/*.pc

}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
