# Library for command-line editing
#
# BE CAREFUL: macOS provide libedit

# shellcheck disable=SC2034
libs_lic='GPL-3.0-or-later'
libs_ver=8.3
libs_url=(
    https://mirrors.ustc.edu.cn/gnu/readline/readline-$libs_ver.tar.gz
    https://ftpmirror.gnu.org/gnu/readline/readline-$libs_ver.tar.gz
)
libs_sha=fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc
libs_dep=(ncurses)

# patch fails
#libs_patches=(
#    https://ftpmirror.gnu.org/gnu/readline/readline-8.3-patches/readline83-001
#)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # use ncurses instead of termcap
    --with-curses
    --enable-multibyte

    # no share/readline/*.c
    --disable-install-examples

    # static
    --disable-shared
    --enable-static
)

libs_build() {
    configure && make && make check || return 1

    pkgfile libreadline -- make install-static
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
