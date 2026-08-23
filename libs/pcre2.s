# Perl compatible regular expressions library with a new API
#
# shellcheck disable=SC2034
libs_des="Perl compatible regular expressions library with a new API"
libs_lic="BSD-3-Clause"
libs_ver=10.47
libs_url=https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$libs_ver/pcre2-$libs_ver.tar.bz2
libs_sha=47fe8c99461250d42f89e6e8fdaeba9da057855d06eb7fc08d9ca03fd08d7bc7

libs_deps=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-pcre2-8
    --enable-pcre2-16
    --enable-pcre2-32

    --enable-unicode
    --enable-newline-is-anycrlf

    # static only
    --disable-shared
    --enable-static
)

if is_mingw; then
    libs_args+=(--disable-jit)
else
    libs_args+=(--enable-jit)
fi

libs_build() {
    configure

    make

    # fix pcre2-config
    #  1. replace hardcoded PREFIX, refer to helpers.sh:_pack()
    #  2. fix missing -DPCRE2_STATIC: pcre2-posix depends on pcre2-8 which has this macro defined
    sed -i pcre2-config \
        -e 's/echo \$includes *$/& -DPCRE2_STATIC/'

    # no prograns or docs
    cmdlet.pkgfile libpcre2 -- make.install \
        bin_PROGRAMS= \
        dist_man_MANS= \
        dist_doc_DATA= \
        dist_html_DATA=

    for x in pcre2grep pcre2test; do
        cmdlet.install "$x"
    done

    cmdlet.check pcre2grep --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
