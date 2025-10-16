# BSD-3-Clause
#
# shellcheck disable=SC2034

libs_lic="BSD"
libs_ver=1.3.7
libs_url=https://downloads.xiph.org/releases/vorbis/libvorbis-$libs_ver.tar.xz
libs_sha=b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b
libs_dep=(libogg)

libs_args=()

libs_build() {
    cmake -S . -B build &&

    make -C build &&

    library vorbis \
            include/vorbis  include/vorbis/*.h \
            lib             build/lib/*.a \
            lib/pkgconfig   build/*.pc

}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
