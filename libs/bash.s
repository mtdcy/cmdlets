# Bourne-Again SHell, a UNIX command interpreter
#
# HEAD version for feature inspection:
#   #1. DON'T use this version as default interpreter

# shellcheck disable=SC2034
libs_lic=GPLv3+
libs_ver=5.3.15
libs_url=(
    https://mirrors.ustc.edu.cn/gnu/bash/bash-${libs_ver%.*}.tar.gz
    https://github.com/bminor/bash/archive/refs/tags/bash-${libs_ver%.*}.tar.gz
    https://ftpmirror.gnu.org/gnu/bash/bash-${libs_ver%.*}.tar.gz
)
libs_sha=6c377fd89688d0ce9bef112ce82c83418f1b6d5457ad6ea2ef2d8558bd552f2c

PATCHLEVEL=${libs_ver##*.}

libs_resources=()
for ((i = 1; i <= PATCHLEVEL; i++)); do
    libs_resources+=("https://mirrors.ustc.edu.cn/gnu/bash/bash-5.3-patches/bash53-$( printf "%03d" "$i")")
done

libs_deps=(ncurses readline libiconv)
libs_args=(
    # ncurses + readline
    --with-curses
    --enable-readline
    --with-installed-readline
    --enable-static-link

    # no nls nor libintl
    --disable-nls
    --without-libintl-prefix

    # https://github.com/robxu9/bash-static/blob/master/build.sh
    --without-bash-malloc
)

# fix 'error: cannot guess build type'
is_darwin || libs_args+=(--build="$( uname -m)-unknown-linux-gnu")

if is_cygwin; then
    # https://github.com/msys2/MSYS2-packages/tree/master/bash
    libs_patches=(
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/bash/0001-bash-4.4-cygwin.patch
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/bash/0002-bash-4.3-msysize.patch
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/bash/0005-bash-4.3-msys2-fix-lineendings.patch
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/bash/0006-bash-4.3-add-pwd-W-option.patch
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/bash/0007-fix-static-build.patch
    )
    #libs_args+=(
    #    bash_cv_dev_stdin=present
    #    bash_cv_dev_fd=standard
    #    bash_cv_termcap_lib=libncurses
    #)
fi

libs_build() {
    for x in bash53-*; do
        slogi "$_EMOJI_RUN" "patch $x"
        patch -Nbp0 < "$x" || patch -Nbp1 < "$x"
    done

    # macOS defined this:
    #  refer to https://github.com/Homebrew/homebrew-core/blob/90c02007778049214b6c76120bb74ef702eec449/Formula/b/bash.rb
    CFLAGS+=" -DSSH_SOURCE_BASHRC"

    # some version needs this
    CPPFLAGS="$CFLAGS"

    # musl has strtoimax
    if is_musl; then
        # https://github.com/robxu9/bash-static/blob/master/custom/bash-musl-strtoimax-debian-1023053.patch
        sed -i 's/bash_cv_func_strtoimax =.*;/bash_cv_func_strtoimax = no;/' m4/strtoimax.m4
        slogcmd autoconf -f
    elif is_cygwin; then
        slogcmd autoconf -f
        libs.requires -D__MSYS__ # patch: 0005-bash-4.3-msys2-fix-lineendings.patch
    fi

    configure

    make

    # install
    cmdlet.install bash

    # check
    cmdlet.check bash --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
