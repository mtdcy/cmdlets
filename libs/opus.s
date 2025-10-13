# Audio Codec
#
# shellcheck disable=SC2034

libs_lic="BSD-3-Clause"
libs_ver=1.5.2
libs_url=https://downloads.xiph.org/releases/opus/opus-$libs_ver.tar.gz
libs_sha=65c1d2f78b9f2fb20082c38cbe47c951ad5839345876e46941612ee87f9a7ce1
libs_dep=()

libs_args=(
    --disable-extra-programs
    --disable-shared
    --enable-static
)

libs_build() {
    # force configure instead of cmake
    rm CMakeLists.txt

    configure && 

    make check && 

    library opus \
       include/opus include/opus*.h \
       lib .libs/*.a \
       lib/pkgconfig opus.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
