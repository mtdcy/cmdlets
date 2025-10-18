# GNU libiconv is a conversion library

# shellcheck disable=SC2034
libs_desc="Character sets conversion library"
libs_page="https://www.gnu.org/software/libiconv/"

libs_lic="GPL-3.0-or-later|LGPL-2.0-or-later"
libs_ver=1.18
libs_url=https://ftpmirror.gnu.org/gnu/libiconv/libiconv-$libs_ver.tar.gz
libs_sha=3b08f5f4f9b4eb82f151a7040bfd6fe6c6fb922efe4b1659c66ea933276965e8

is_darwin && libs_patches=(
    https://raw.githubusercontent.com/Homebrew/patches/9be2793af/libiconv/patch-utf8mac.diff
)

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

#  Linux glibc/musl provides iconv.h, but we want universal static binaries, 
#  so always link libiconv for both Linux and macOS
libs_build() {
    deparallelize

    # Reported at https://savannah.gnu.org/bugs/index.php?66170
    is_darwin && export CFLAGS+=" -Wno-incompatible-function-pointer-types"

    sed -i '/utf8.h/a utf8mac.h \\' lib/Makefile.in

    configure && 

    make -f Makefile.devel                    \
        CC="'$CC'"                            \
        CFLAGS="'$CFLAGS $CPPFLAGS $LDFLAGS'" \
        ACLOCAL=aclocal                       \
        AUTOMAKE=automake                     \
        &&

    make && make check || return $?

    pkgfile libiconv -- make install &&

    cmdlet  src/iconv_no_i18n iconv &&

    # visual check
    check iconv --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4

# not necessary, make -f Makefile.devel will update lib/flags.h
# keep it here for inline patch example
__END__
diff --git a/lib/flags.h b/lib/flags.h
index d7cda21..4cabcac 100644
--- a/lib/flags.h
+++ b/lib/flags.h
@@ -14,6 +14,7 @@

 #define ei_ascii_oflags (0)
 #define ei_utf8_oflags (HAVE_ACCENTS | HAVE_QUOTATION_MARKS | HAVE_HANGUL_JAMO)
+#define ei_utf8mac_oflags (HAVE_ACCENTS | HAVE_QUOTATION_MARKS | HAVE_HANGUL_JAMO)
 #define ei_ucs2_oflags (HAVE_ACCENTS | HAVE_QUOTATION_MARKS | HAVE_HANGUL_JAMO)
 #define ei_ucs2be_oflags (HAVE_ACCENTS | HAVE_QUOTATION_MARKS | HAVE_HANGUL_JAMO)
 #define ei_ucs2le_oflags (HAVE_ACCENTS | HAVE_QUOTATION_MARKS | HAVE_HANGUL_JAMO)
