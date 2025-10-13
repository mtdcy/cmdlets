# BSD
#
# shellcheck disable=SC2034

libs_ver=1.8.0
libs_url=https://github.com/cisco/openh264/archive/v$libs_ver.tar.gz
libs_zip=openh264-$libs_ver.tar.gz
libs_sha=08670017fd0bb36594f14197f60bebea27b895511251c7c64df6cd33fc667d34

libs_build() {
    # remove default value, using env instead
    sed -i '/^PREFIX=*/d' Makefile

    is_msys && {
        sed -i '/^CC =/d' build/platform-mingw_nt.mk
        sed -i '/^CXX =/d' build/platform-mingw_nt.mk
        sed -i '/^AR =/d' build/platform-mingw_nt.mk
    }

    make libopenh264.a openh264-static.pc &&

    cp openh264-static.pc openh264.pc &&
    
    library openh264 \
        include/wels codec/api/svc/*.h \
        lib *.a \
        lib/pkgconfig openh264.pc
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
