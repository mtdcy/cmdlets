# General-purpose data compression with high compression ratio
# shellcheck disable=SC2034

upkg_name=xz
upkg_lic="BSD"
upkg_ver=5.8.1
upkg_url=(
    https://github.com/tukaani-project/xz/releases/download/v$upkg_ver/xz-$upkg_ver.tar.xz
    https://downloads.sourceforge.net/project/lzmautils/xz-$upkg_ver.tar.xz
    https://mirrors.wikimedia.org/ubuntu/pool/main/x/xz-utils/xz-utils_$upkg_ver.orig.tar.xz
)
upkg_zip=$upkg_name-$upkg_ver.tar.xz
upkg_sha=0b54f79df85912504de0b14aec7971e3f964491af1812d83447005807513cd9e
upkg_dep=()

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # no these for single static executables.
    --disable-nls --disable-rpath

    --disable-shared
    --enable-static
)

upkg_static() {
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
