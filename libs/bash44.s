# Bourne-Again SHell, a UNIX command interpreter

# shellcheck disable=SC2034
libs_lic="GPL-3.0-or-later"
libs_ver=4.4.18
libs_url=https://ftpmirror.gnu.org/gnu/bash/bash-$libs_ver.tar.gz
libs_sha=604d9eec5e4ed5fd2180ee44dd756ddca92e0b6aa4217bbab2b6227380317f23
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
    CPPFLAGS+="$CFLAGS"

    export CFLAGS CPPFLAGS

    configure &&

    make &&

    # install versioned bash
    cmdlet bash bash@${libs_ver%.*} bash@${libs_ver%%.*} &&

    check bash@4.4 --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
