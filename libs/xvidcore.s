# High-performance, high-quality MPEG-4 video library

# shellcheck disable=SC2034
libs_lic="GPL-2.0-or-later"
libs_ver=1.3.7
libs_url=https://downloads.xvid.com/downloads/xvidcore-$libs_ver.tar.bz2
libs_sha=aeeaae952d4db395249839a3bd03841d6844843f5a4f84c271ff88f7aa1acff7

libs_patches=(
    https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-xvidcore/0001-remove-dll-option-clang.patch
)

libs_build() {
    pushd build/generic

    if is_mingw; then
        #1. x86_64-w64-mingw32-gcc-posix: error: unrecognized command-line option ‘-mno-cygwin’; did you mean ‘-mno-clwb’?
        #2. fix STATIC_LIB 
        sed -i configure \
            -e 's/"-mno-cygwin"/""/g' \
            -e 's/STATIC_LIB="xvidcore/STATIC_LIB="libxvidcore/g' \
            || die "hack configure failed."
    fi

    configure

    make libxvidcore.a

    # create pc file
    pkgconf xvidcore.pc -lxvidcore

    pkginst xvidcore                         \
        include         ../../src/xvid.h     \
        lib             =build/libxvidcore.a \
        lib/pkgconfig   xvidcore.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
