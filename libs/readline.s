# Library for command-line editing
#
# BE CAREFUL: macOS provide libedit

# shellcheck disable=SC2034
libs_stable=1 # depends on patches

READLINE_URL=${LIBS_MIRROR_GNU:-https://ftpmirror.gnu.org/gnu}/readline

libs_lic='GPLv3.0+'
libs_ver=8.3
libs_url=$READLINE_URL/readline-$libs_ver.tar.gz
libs_sha=fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc

libs_deps=(ncurses)

libs_patches=(
    $READLINE_URL/readline-$libs_ver-patches/readline83-001
    $READLINE_URL/readline-$libs_ver-patches/readline83-002
    $READLINE_URL/readline-$libs_ver-patches/readline83-003
)

if is_mingw; then
    # https://github.com/msys2/MINGW-packages/tree/master/mingw-w64-readline
    libs_patches+=(
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-readline/0001-sigwinch.patch
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-readline/0002-event-hook.patch
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-readline/0003-no-winsize.patch
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-readline/0004-locale.patch
    )
elif is_cygwin; then
    # https://github.com/msys2/MSYS2-packages/tree/master/readline
    libs_patches+=(
        #https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/readline/readline-6.3-msys2.patch
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/readline/readline-6.3-paste-utf8.patch
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/readline/readline-7.0.3-3.clipboard.patch
        #https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/readline/readline-7.0.3-3.src.patch
    )
fi

libs_args=(
    # static only
    --enable-static --disable-shared

    # use ncurses instead of termcap
    --with-curses

    # no share/readline/*.c
    --disable-install-examples
)

libs_build() {
    # set ncurses flags
    #libs.requires ncurses # => wrong -lncurses -lreadline order cause zig cc error: duplicate symbol
    libs.requires -DNCURSES_STATIC
    # 解决链接 ncurses 后 'UP' 等符号多重定义的问题
    #libs.requires -DNCURSES_VERSION -DNEED_EXTERN_PC

    # force ncurses: --with-curses not working
    #is_listed ncurses libs_deps && export bash_cv_termcap_lib=libncurses

    configure

    make

    make check

    cmdlet.pkgfile libreadline -- make install-static

    # check linkage by build a program
    make readline TERMCAP_LIB="-L$PREFIX/lib -lncurses"

    cmdlet.install ./readline

    cmdlet.verify readline
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
