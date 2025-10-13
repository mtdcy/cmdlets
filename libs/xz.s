# General-purpose data compression with high compression ratio
# shellcheck disable=SC2034

libs_name=xz
libs_lic="BSD"
libs_ver=5.8.1
libs_url=(
    https://github.com/tukaani-project/xz/releases/download/v$libs_ver/xz-$libs_ver.tar.xz
    https://downloads.sourceforge.net/project/lzmautils/xz-$libs_ver.tar.xz
    https://mirrors.wikimedia.org/ubuntu/pool/main/x/xz-utils/xz-utils_$libs_ver.orig.tar.xz
)
libs_zip=$libs_name-$libs_ver.tar.xz
libs_sha=0b54f79df85912504de0b14aec7971e3f964491af1812d83447005807513cd9e
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # no these for single static executables.
    --disable-nls --disable-rpath

    --disable-shared
    --enable-static
)

libs_build() {
    rm CMakeLists.txt # force use configure

    configure &&

    make V=1 &&

    # check & install
    make check &&

    # make install
    library liblzma \
        include         src/liblzma/api/lzma.h \
        include/lzma    $(ls src/liblzma/api/lzma/*.h | xargs) \
        lib             src/liblzma/.libs/liblzma.{a,la} \
        lib/pkgconfig   src/liblzma/liblzma.pc \
        &&

    cmdlet src/xz/xz xz xzcat lzcat lzma &&
    cmdlet src/xzdec/xzdec &&
    cmdlet src/xzdec/lzmadec &&
    cmdlet src/lzmainfo/lzmainfo &&
    cmdlet src/scripts/xzdiff xzdiff lzdiff  &&
    cmdlet src/scripts/xzgrep xzgrep xzegrep xzfgrep &&
    cmdlet src/scripts/xzmore xzmore lzmore &&
    cmdlet src/scripts/xzless xzless lzless &&

    # visual verify
    check xz --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
