# Bourne-Again SHell, a UNIX command interpreter
#
# 3.2: a classic version

# shellcheck disable=SC2034
libs_lic="GPL-3.0-or-later"
libs_ver=3.2.57
libs_url=https://ftpmirror.gnu.org/gnu/bash/bash-$libs_ver.tar.gz
libs_sha=3fa9daf85ebf35068f090ce51283ddeeb3c75eb5bc70b1a4a7cb05868bfe06a4
libs_dep=(ncurses libiconv)

# this formula is used to compatible check, don't enable any extra features
libs_args=(
    --with-curses
    --enable-readline
    --without-installed-readline
    --with-included-gettext

    --disable-nls

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
is_darwin || libs_args+=( --build="$(uname -m)-unknown-linux-gnu" )

libs_build() {
    libs.requires.c89 || true

    # bash 3.2 won't start with `-Os'
    CFLAGS="${CFLAGS//-Os/-O2}"

    # macOS defined this:
    #  refer to https://github.com/Homebrew/homebrew-core/blob/90c02007778049214b6c76120bb74ef702eec449/Formula/b/bash.rb
    CFLAGS+=" -DSSH_SOURCE_BASHRC"

    # some version needs this
    CPPFLAGS+=" $CFLAGS"

    export CFLAGS CPPFLAGS

    is_mingw && sed '/cross_cache=/d' -i configure

    configure

    make

    # install versioned bash
    cmdlet bash bash@${libs_ver%.*} bash@${libs_ver%%.*} &&

    check bash@3.2 --version
}

libs.depends ! is_mingw

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
