# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
#
# GNU libiconv is a conversion library

# shellcheck disable=SC2034
libs_desc="Character sets conversion library"
libs_page="https://www.gnu.org/software/libiconv/"
libs_stable=1 # depends on patches

libs_lic="GPL-3.0-or-later|LGPL-2.0-or-later"
libs_ver=1.19
libs_url=https://ftpmirror.gnu.org/gnu/libiconv/libiconv-$libs_ver.tar.gz
libs_sha=88dd96a8c0464eca144fc791ae60cd31cd8ee78321e67397e25fc095c4a19aa6

is_darwin && libs_patches=(
    https://raw.githubusercontent.com/Homebrew/patches/9be2793af/libiconv/patch-utf8mac.diff
)

# https://github.com/msys2/MSYS2-packages/tree/master/libiconv
is_cygwin && libs_patches=(
    https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/libiconv/1.16-aliases.patch
    https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/libiconv/1.16-cross-install.patch
    https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/libiconv/1.16-wchar.patch
    https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/libiconv/libiconv-1.16-msysize.patch
    #https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/libiconv/0001-fixes-building-with-gcc-15.patch
)

# https://github.com/msys2/MINGW-packages/tree/master/mingw-w64-libiconv

libs_args=(
    # static only
    --enable-static --disable-shared

    --enable-pic
    --enable-extra-encodings

    # no these for single static executables
    --disable-nls
    --without-libintl-prefix
)

#  Linux glibc/musl provides iconv.h, but we want universal static binaries,
#  so always link libiconv for both Linux and macOS
libs_build() {
    # deparallelize
    libs.requires -j1

    # Reported at https://savannah.gnu.org/bugs/index.php?66170
    if is_darwin; then
        libs.requires -Wno-incompatible-function-pointer-types
        sed -i '/utf8.h/a utf8mac.h \\' lib/Makefile.in
    fi

    if is_cygwin; then
        # borrow from https://github.com/msys2/MSYS2-packages/blob/master/libiconv/PKGBUILD
        #  => why this build proc not working for linux and macOS
        cp -f srcm4/* m4/
        (   
            cd libcharset
            slogcmd autoreconf -fiv
        )
        slogcmd autoreconf -fiv

        configure

        make
    else
        configure

        # generate files
        make -f Makefile.devel all \
            CC="$CC" CFLAGS="$CFLAGS $CPPFLAGS $LDFLAGS" \
            ACLOCAL=aclocal AUTOMAKE=automake
    fi

    is_xbuild || make check

    cmdlet.pkgconf iconv -liconv -lcharset
    cmdlet.pkgconf libiconv -liconv -lcharset

    cmdlet.pkginst libiconv \
            include/iconv.h lib/libcharset.h lib/localcharset.h \
            lib/.libs/libiconv.a lib/libcharset.a \
            iconv.pc libiconv.pc

    cmdlet.install src/iconv_no_i18n iconv

    # visual check
    cmdlet.verify -- iconv --version
}
