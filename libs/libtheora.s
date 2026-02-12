# An open video codec developed by the Xiph.org
#
# shellcheck disable=SC2034

libs_lic="BSD-3-Clause"
libs_ver=1.2.0
libs_url=https://downloads.xiph.org/releases/theora/libtheora-$libs_ver.tar.gz
libs_sha=279327339903b544c28a92aeada7d0dcfd0397b59c2f368cc698ac56f515906e

libs_deps=(libogg libvorbis)
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-ogg=$PREFIX
    --with-vorbis=$PREFIX
    
    --disable-examples
    --disable-oggtest
    --disable-vorbistest
    --disable-spec

    # static only
    --disable-shared
    --enable-static
)

# fix 'error: cannot guess build type'
is_darwin || libs_args+=( --build="$(uname -m)-linux-gnu" )

libs_build() {
    # parallel is broken (libtheoraenc is missing sometimes)
    deparallelize

    if is_mingw; then
        # /usr/bin/x86_64-w64-mingw32-ld: cannot find -ltheoradec: No such file or directory
        sed -i '/THENC_VERSION_ARG/s/ -ltheoradec//g' configure
        # fix syntax of export symbols files
        sed -i 's/^EXPORTS//' win32/xmingw32/*.def
    fi

    configure 

    make 

    make check 

    sed -i 's/^SUBDIRS = .*/SUBDIRS = lib include/' Makefile

    pkgfile libtheora -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
