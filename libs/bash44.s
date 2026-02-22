# Bourne-Again SHell, a UNIX command interpreter

libs_targets=( linux darwin )

# shellcheck disable=SC2034
libs_lic="GPL-3.0-or-later"
libs_ver=4.4.18
libs_url=https://ftpmirror.gnu.org/gnu/bash/bash-$libs_ver.tar.gz
libs_sha=604d9eec5e4ed5fd2180ee44dd756ddca92e0b6aa4217bbab2b6227380317f23

libs_deps=( ncurses readline libiconv )

# this formula is used to compatible check, don't enable any extra features
libs_args=(
    --with-curses
    --enable-readline
    --without-installed-readline
    --without-included-gettext

    --disable-nls

    # https://github.com/robxu9/bash-static/blob/master/build.sh
    --without-bash-malloc
)

# fix 'error: cannot guess build type'
is_darwin || libs_args+=( --build="$(uname -m)-unknown-linux-gnu" )

libs_build() {
    # ISO C99 and later do not support implicit function declarations
    if is_clang; then
        libs.requires                          \
            -Wno-int-conversion                \
            -Wno-implicit-int                  \
            -Wno-incompatible-pointer-types    \
            -Wno-implicit-function-declaration
    fi

    # bash 3.2 won't start with `-Os'
    CFLAGS="${CFLAGS//-Os/-O2}"

    # macOS defined this:
    #  refer to https://github.com/Homebrew/homebrew-core/blob/90c02007778049214b6c76120bb74ef702eec449/Formula/b/bash.rb
    libs.requires -DSSH_SOURCE_BASHRC

    # error: redefinition of 'sys_siglist' with a different type: 'char *[32]' vs 'const char *const[32]'
    is_darwin && libs.requires -D_POSIX_C_SOURCE -D_DARWIN_C_SOURCE

    configure

    make

    # install versioned bash
    cmdlet.install bash bash@${libs_ver%.*} bash@${libs_ver%%.*} &&

    cmdlet.check bash@4.4 --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
