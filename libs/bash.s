# Bourne-Again SHell, a UNIX command interpreter

# shellcheck disable=SC2034
libs_stable=1

libs_lic=GPLv3+
libs_ver=5.3
libs_rev=3
libs_url=${_LIBS_MIRROR_GNU:-https://ftpmirror.gnu.org/gnu}/bash/bash-5.3.tar.gz
libs_sha=6c377fd89688d0ce9bef112ce82c83418f1b6d5457ad6ea2ef2d8558bd552f2c

# debian/ubuntu patches
libs_resources=(
    https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/bash/5.3-3ubuntu1/bash_5.3-3ubuntu1.debian.tar.xz
)

# @debian/patches/series
libs_patches=(
    debian/patches/bash53-001.diff
    debian/patches/bash53-002.diff
    debian/patches/bash53-003.diff
    debian/patches/bash53-004.diff
    debian/patches/bash53-005.diff
    debian/patches/bash53-006.diff
    debian/patches/bash53-007.diff
    debian/patches/bash53-008.diff
    debian/patches/bash53-009.diff
    debian/patches/input-err.diff
    debian/patches/bash-aliases-repeat.diff
    debian/patches/readline-need-extern-pc.diff
)

libs_deps=(ncurses readline)
libs_args=(
    # ncurses + readline
    --with-curses
    --enable-readline
    --with-installed-readline

    # no nls nor libintl
    --disable-nls
    --without-libintl-prefix
    --without-libiconv-prefix

    # https://github.com/robxu9/bash-static/blob/master/build.sh
    --without-bash-malloc
)

is_darwin || libs_args+=(--enable-static-link)

# fix 'error: cannot guess build type'
is_darwin || libs_args+=(--build="$( uname -m)-unknown-linux-gnu")

if is_cygwin; then
    libs_patches+=(
        #https://cygwin.com/cgit/cygwin-packages/bash/plain/bash-5.2-cygwin.patch
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/bash/0001-bash-4.4-cygwin.patch
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/bash/0007-fix-static-build.patch
    )
    libs_args+=(
        bash_cv_dev_stdin=present
        bash_cv_dev_fd=standard
        #bash_cv_termcap_lib=libncurses
    )
fi

libs_build() {
    # 回收版本号
    cmdlet.disclaim 5.3.15

    # macOS defined this:
    #  refer to https://github.com/Homebrew/homebrew-core/blob/90c02007778049214b6c76120bb74ef702eec449/Formula/b/bash.rb
    libs.requires -DSSH_SOURCE_BASHRC

    slogcmd autoconf -f

    configure

    make bash$_BINEXT

    # find out real version
    libs_ver+=".$(grep -Fw "#define PATCHLEVEL" patchlevel.h | cut -d' ' -f3)"

    # install
    cmdlet.install bash

    # check
    cmdlet.check bash --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
