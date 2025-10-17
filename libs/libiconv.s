# GNU libiconv is a conversion library

# shellcheck disable=SC2034
libs_desc="Character sets conversion library"
libs_page="https://www.gnu.org/software/libiconv/"

libs_lic="GPL-3.0-or-later|LGPL-2.0-or-later"
libs_ver=1.18
libs_url=https://ftpmirror.gnu.org/gnu/libiconv/libiconv-$libs_ver.tar.gz
libs_sha=3b08f5f4f9b4eb82f151a7040bfd6fe6c6fb922efe4b1659c66ea933276965e8

# fails
#is_darwin && libs_patches=(
#    https://raw.githubusercontent.com/Homebrew/patches/9be2793af/libiconv/patch-utf8mac.diff
#)

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --enable-silent-rules

    --enable-pic
    --enable-extra-encodings

    # no these for single static executables
    --disable-nls

    # static only
    --disable-shared
    --enable-static
)

#  Linux glibc/musl provides iconv.h 
libs_build() {
    # Reported at https://savannah.gnu.org/bugs/index.php?66170
    is_darwin && export CFLAGS+=" -Wno-incompatible-function-pointer-types"


    configure && make && make check || return $?

    pkgfile libiconv -- make install &&

    cmdlet  src/iconv_no_i18n iconv &&

    # visual check
    check iconv --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
