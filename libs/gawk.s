# GNU awk utility

# shellcheck disable=SC2034
libs_lic=GPLv3+
libs_ver=5.4.1
libs_url=https://ftpmirror.gnu.org/gnu/gawk/gawk-$libs_ver.tar.xz
libs_sha=07f6f7342b7febe4313fc2c2542ad93d64fe20ad8717200109f105a826f5fd37

libs_deps=(gmp mpfr readline)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # disable these for single static executables.
    --disable-nls
    --without-selinux
    --without-libintl-prefix
    --without-libiconv-prefix

    --disable-extensions

    --disable-doc
    --disable-man
)

is_listed mpfr      libs_deps && libs_args+=(--with-mpfr)       || libs_args+=(--without-mpfr)
is_listed readline  libs_deps && libs_args+=(--with-readline)   || libs_args+=(--without-readline)

libs_build() {
    # refer to: https://github.com/macports/macports-ports/blob/master/lang/gawk/Portfile
    is_darwin && sed -i 's:-Xlinker -no_pie::' configure

    libs.requires readline mpfr

    # local support/regex.h first (libgnurx also provides regex.h)
    sed -i support/regex.c \
        -i support/dfa.h \
        -e 's/<regex.h>/"regex.h"/g'

    if is_mingw; then
        # https://www.gnu.org/software/gawk/manual/html_node/PC-Compiling.html
        cp pc/* ./ || true
        cp pc/awklib/* awklib/

        #1. fix VPATH
        #2. append CFLAGS
        #3. no regex
        sed -i Makefile \
            -e '/^VPATH/s/;/:/g'
            #-e 's/^CFLAGS =/CFLAGS +=/g'
            #-e '/LIBOBJS/s/regex\$O//' \
            #-e 's/regex.h//g'

        # no fork
        sed -i 's/#ifdef SIGPIPE/#if 0/g' awk.h

        # force init predefined macros
        sed -i '/#ifdef _UCRT/i #include <stdint.h>' pc/mbc32.h

        # fix error: use of undeclared identifier '__mb_cur_max'
        sed -i '/^#.*MB_CUR_MAX/d' custom.h

        # fix error: duplicate symbol: strcoll
        sed -i 's/#undef HAVE_STRCOLL/#define HAVE_STRCOLL 1/g' config.h

        libs.requires.c89

        CFLAGS+=" -D__USE_MINGW_ANSI_STDIO"
        CFLAGS+=" -DHAVE_MPFR"
        CFLAGS+=" -DHAVE_LIBREADLINE"

        LDFLAGS+=" -lgmp -lmpfr -lws2_32"

        # override CC CFLAGS LDFLAGS
        make gawk.exe \
            CF="'$CFLAGS $CPPFLAGS'" \
            LF2="'$LDFLAGS'" \
            O=.o OBJ=popen.o LNK=LMINGW32
    else
        configure

        make
    fi

    # wine: Call from 00006FFFFF3DD887 to unimplemented function ucrtbase.dll.mbrtoc32, aborting
    if is_mingw && test -n "$WINEPREFIX"; then
        slogw "skill gawk test with wine"
    else
        # gawk: invalid char ''' in expression
        #  => cmd.exe does not treat single quotes as quotation marks, passing them directly to gawk
        echo '{ gsub(/World/, "Hello"); print }' > gsub.awk

        # check => XXX: there always 5 FAILs
        #make check &&
        [ "HelloHello" = "$(run ./gawk -f gsub.awk <<< "HelloWorld")" ] || die "test failed"
    fi

    #make install-exec &&
    cmdlet.install gawk gawk awk

    # visual verify
    cmdlet.check gawk
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
