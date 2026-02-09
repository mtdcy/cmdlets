# Library for command-line editing
#
# BE CAREFUL: macOS provide libedit
libs_stable=1

# shellcheck disable=SC2034
libs_lic='GPLv3.0+'
libs_ver=8.3
libs_url=(
    https://mirrors.ustc.edu.cn/gnu/readline/readline-$libs_ver.tar.gz
    https://ftpmirror.gnu.org/gnu/readline/readline-$libs_ver.tar.gz
)
libs_sha=fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc
libs_deps=( ncurses )

libs_patches=(
    https://ftp.gnu.org/gnu/readline/readline-8.3-patches/readline83-001
    https://ftp.gnu.org/gnu/readline/readline-8.3-patches/readline83-002
    https://ftp.gnu.org/gnu/readline/readline-8.3-patches/readline83-003
)
libs_patch_level=0

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # use ncurses instead of termcap
    --with-curses

    # no share/readline/*.c
    --disable-install-examples

    # static
    --disable-shared
    --enable-static
)

libs_build() {
    # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mingw-w64-readline
    # windows don't have struct winsize
    is_mingw && sed -i '/^extern int _rl_tcgetwinsize/i struct winsize;' rlwinsize.h

    configure

    make

    make check

    pkgfile libreadline -- make install-static
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
