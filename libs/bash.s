# Bourne-Again SHell, a UNIX command interpreter
#
# HEAD version for feature inspection:
#   #1. DON'T use this version as default interpreter

# shellcheck disable=SC2034
libs_lic=GPLv3+
libs_ver=5.3
libs_url=(
    https://github.com/bminor/bash/archive/refs/tags/bash-$libs_ver.tar.gz
    https://ftpmirror.gnu.org/gnu/bash/bash-$libs_ver.tar.gz
)

libs_sha=6c377fd89688d0ce9bef112ce82c83418f1b6d5457ad6ea2ef2d8558bd552f2c

libs_deps=( ncurses readline libiconv ) 
libs_args=(
    --disable-option-checking 

    --with-curses
    --enable-readline
    --without-installed-readline
    --without-included-gettext

    --disable-nls

    # https://github.com/robxu9/bash-static/blob/master/build.sh
    --without-bash-malloc
)

is_mingw || libs_args+=(
    # enable features for HEAD version
    --enable-alias
    --enable-alt-array-implementation
    --enable-arith-for-command
    --enable-array-variables
    --enable-brace-expansion
    --enable-casemod-attributes
    --enable-casemod-expansions
    --enable-command-timing
    --enable-cond-command
    --enable-cond-regexp
    --enable-coprocesses
    --enable-direxpand-default
    --enable-directory-stack
    --enable-dparen-arithmetic
    --enable-extended-glob
    --enable-extended-glob-default
    --enable-function-import
    --enable-glob-asciiranges-default
    --enable-help-builtin
    --enable-job-control
    --enable-multibyte
    --enable-net-redirections
    --enable-process-substitution
    --enable-progcomp
    --enable-select
    #--enalbe-prompt-string-decoding -> unrecognized
)

# fix 'error: cannot guess build type'
is_darwin || libs_args+=( --build="$(uname -m)-unknown-linux-gnu" )

is_mingw && libs_resources=(
    https://mirrors.ustc.edu.cn/cygwin/x86_64/release/cygwin/cygwin-3.7.0-0.395.ga7c614986ab2-x86_64.tar.xz
    https://mirrors.ustc.edu.cn/cygwin/x86_64/release/cygwin/cygwin-devel/cygwin-devel-3.7.0-0.395.ga7c614986ab2-x86_64.tar.xz
)

libs_build() {

    # macOS defined this:
    #  refer to https://github.com/Homebrew/homebrew-core/blob/90c02007778049214b6c76120bb74ef702eec449/Formula/b/bash.rb
    CFLAGS+=" -DSSH_SOURCE_BASHRC"

    # some version needs this
    CPPFLAGS="$CFLAGS"

    # musl has strtoimax
    if is_musl; then
        # https://github.com/robxu9/bash-static/blob/master/custom/bash-musl-strtoimax-debian-1023053.patch
        sed -i 's/bash_cv_func_strtoimax =.*;/bash_cv_func_strtoimax = no;/' m4/strtoimax.m4
        autoconf -f
    elif is_mingw; then
        export CFLAGS+=" -I$PWD/usr/include -Dmain=WinMain"
        export LDFLAGS+=" -L$PWD/usr/lib -lcygwin" 
    fi

    configure

    make

    # install
    cmdlet.install bash

    # check
    cmdlet.check bash --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
