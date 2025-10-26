
#
# shellcheck disable=SC2034
libs_des="Perl compatible regular expressions library with a new API"
libs_lic="BSD-3-Clause"
libs_ver=10.47
libs_url=https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$libs_ver/pcre2-$libs_ver.tar.bz2
libs_sha=47fe8c99461250d42f89e6e8fdaeba9da057855d06eb7fc08d9ca03fd08d7bc7
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

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    configure  && make || return $?

    # no prograns or docs
    pkgfile libpcre2 -- make install \
        bin_PROGRAMS=                \
        dist_man_MANS=               \
        dist_doc_DATA=               \
        dist_html_DATA=              \
        &&

    cmdlet ./pcre2grep &&
    cmdlet ./pcre2test &&

    check pcre2grep --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
