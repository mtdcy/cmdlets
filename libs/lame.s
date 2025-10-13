# License: LGPL
#
# shellcheck disable=SC2034

libs_lic="LGPL"
libs_ver=3.100
libs_url=https://sourceforge.net/projects/lame/files/lame/$libs_ver/lame-$libs_ver.tar.gz
libs_sha=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e

libs_args=(
    --disable-frontend
    --enable-nasm
    --disable-shared
    --enable-static
)

libs_build() {
    # Fix undefined symbol error _lame_init_old
    # https://sourceforge.net/p/lame/mailman/message/36081038/
    sed -i '/lame_init_old/d' include/libmp3lame.sym

    configure &&

    make check &&
    
    library mp3lame \
       include/lame include/lame.h \
       lib libmp3lame/.libs/libmp3lame.a
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
