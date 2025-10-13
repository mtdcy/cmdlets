
#
# shellcheck disable=SC2034
libs_des="Perl compatible regular expressions library with a new API"
libs_lic="BSD-3-Clause"
libs_ver=10.46
libs_url=https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$libs_ver/pcre2-$libs_ver.tar.bz2
libs_sha=15fbc5aba6beee0b17aecb04602ae39432393aba1ebd8e39b7cabf7db883299f
libs_dep=(zlib bzip2)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-pcre2-16
    --enable-pcre2-32
    --enable-pcre2grep-libz
    --enable-pcre2grep-libbz2
    --enable-jit

    --disable-shared
    --enable-static
)

libs_build() {
    configure  &&

    make &&

    library libpcre2        \
            include         src/pcre2.h src/pcre2posix.h \
            lib             .libs/libpcre2-8.{a,la}  \
                            .libs/libpcre2-16.{a,la}  \
                            .libs/libpcre2-32.{a,la} \
                            .libs/libpcre2-posix.{a,la} \
            lib/pkgconfig   libpcre2-8.pc libpcre2-16.pc libpcre2-32.pc libpcre2-posix.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
