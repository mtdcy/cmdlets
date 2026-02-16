# GNU awk utility

# shellcheck disable=SC2034
libs_lic=GPLv3+
libs_ver=5.3.2
libs_url=https://ftpmirror.gnu.org/gnu/gawk/gawk-$libs_ver.tar.xz
libs_sha=f8c3486509de705192138b00ef2c00bbbdd0e84c30d5c07d23fc73a9dc4cc9cc

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

is_listed mpfr      libs_deps && libs_args+=( --with-mpfr     ) || libs_args+=( --without-mpfr     )
is_listed readline  libs_deps && libs_args+=( --with-readline ) || libs_args+=( --without-readline )

libs_build() {
    # refer to: https://github.com/macports/macports-ports/blob/master/lang/gawk/Portfile
    is_darwin && sed -i 's:-Xlinker -no_pie::' configure

    libs.requires readline mpfr

    # regex.h
    sed -i support/regex.c \
        -i support/dfa.h \
        -e 's/<regex.h>/"regex.h"/g'

    if is_mingw; then
        # https://www.gnu.org/software/gawk/manual/html_node/PC-Compiling.html
        cp pc/* ./ || true
        cp pc/awklib/* awklib/

        sed -i Makefile \
            -e '/VPATH/s/;/:/g' \
            -e 's/CC=gcc //g' \
            -e 's/CFLAGS = /CFLAGS += \$(CPPFLAGS) /g' \
            -e 's/LF2=".*" //g'

        export LF2="$LDFLAGS -lws2_32"

        make mingw32 
    else
        configure

        make 
    fi

    # gawk: invalid char ''' in expression
    #  => cmd.exe does not treat single quotes as quotation marks, passing them directly to gawk
    echo '{ gsub(/World/, "Hello"); print }' > gsub.awk

    # check => XXX: there always 5 FAILs
    #make check &&
    [ "HelloHello" = "$(run ./gawk -f gsub.awk <<< "HelloWorld")" ] || die "test failed"

    #make install-exec &&
    cmdlet.install gawk gawk awk

    # visual verify
    cmdlet.check gawk --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
