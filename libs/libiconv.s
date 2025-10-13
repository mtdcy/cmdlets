# GNU libiconv is a conversion library

# shellcheck disable=SC2034
libs_desc="Character sets conversion library"
libs_page="https://www.gnu.org/software/libiconv/"

libs_lic="GPL-3.0-or-later|LGPL-2.0-or-later"
libs_ver=1.18
libs_url=https://ftpmirror.gnu.org/gnu/libiconv/libiconv-$libs_ver.tar.gz
libs_sha=3b08f5f4f9b4eb82f151a7040bfd6fe6c6fb922efe4b1659c66ea933276965e8

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --enable-silent-rules

    --enable-extra-encodings

    # no these for single static executables
    --disable-nls
    --disable-rpath

    --disable-shared
    --enable-static
)

libs_build() {
    export CFLAGS+=" -Wno-error=implicit-function-declaration"

    configure &&

    # deparallels
    make V=1 -j1 &&

    # check & install
    #make check &&

    #make install &&
    library libiconv \
            include     include/iconv.h \
            lib         lib/.libs/libiconv.{a,la} \
            &&
    library libcharset \
            include     libcharset/include/{libcharset.h,localcharset.h} \
            lib         libcharset/lib/.libs/libcharset.{a,la} \
            &&

    cmdlet  src/iconv_no_i18n iconv &&

    # visual check
    check iconv
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
