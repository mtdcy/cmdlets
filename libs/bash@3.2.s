# Bourne-Again SHell, a UNIX command interpreter
#
# 3.2: a classic version

libs_targets=(linux darwin)

# shellcheck disable=SC2034
libs_lic="GPLv3+"
libs_ver=3.2.57
libs_url=${LIBS_MIRROR_GNU:-https://ftpmirror.gnu.org/gnu}/bash/bash-$libs_ver.tar.gz
libs_sha=3fa9daf85ebf35068f090ce51283ddeeb3c75eb5bc70b1a4a7cb05868bfe06a4

libs_deps=(ncurses readline)

# this formula is used to compatible check, don't enable any extra features
libs_args=(
    # ncurses
    --with-curses

    # readline
    --enable-readline
    --with-installed-readline

    # disabled features
    --disable-nls
    --without-libintl-prefix

    # https://github.com/robxu9/bash-static/blob/master/build.sh
    --without-bash-malloc
)

is_mingw && libs_args+=(
    bash_cv_type_intmax_t=yes

    # no sys/resource.h
    ac_cv_header_sys_resource_h=no
    ac_cv_header_sys_wait_h=no
    ac_cv_header_sys_times_h=no
    ac_cv_header_sys_stream_h=no
    ac_cv_header_sys_socket_h=no
    ac_cv_header_sys_select_h=no
)

# fix 'error: cannot guess build type'
is_darwin || libs_args+=(--build="$( uname -m)-unknown-linux-gnu")

libs_build() {
    # ISO C99 and later do not support implicit function declarations
    libs.requires.c89

    # macOS defined this:
    #  refer to https://github.com/Homebrew/homebrew-core/blob/90c02007778049214b6c76120bb74ef702eec449/Formula/b/bash.rb
    libs.requires -DSSH_SOURCE_BASHRC

    # error: redefinition of 'sys_siglist' with a different type: 'char *[32]' vs 'const char *const[32]'
    is_darwin && libs.requires -D_POSIX_C_SOURCE -D_DARWIN_C_SOURCE

    # bash 3.2 needs this
    export CPPFLAGS+=" $CFLAGS"

    configure

    make

    # install versioned bash
    cmdlet.install bash bash@${libs_ver%.*} bash@${libs_ver%%.*}

    cmdlet.verify -- bash@3.2 --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
