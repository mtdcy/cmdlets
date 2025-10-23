# C XSLT library for GNOME
#
# shellcheck disable=SC2034
libs_ver=5.9
libs_url=https://www.zsh.org/pub/zsh-$libs_ver.tar.xz
libs_sha=9b8d1ecedd5b5e81fbf1918e876752a7dd948e05c1a0dba10ab863842d45acd5
libs_dep=( ncurses pcre2 )

# Use Debian patches to backport `pcre2` support:
# * https://github.com/zsh-users/zsh/commit/b62e911341c8ec7446378b477c47da4256053dc0
# * https://github.com/zsh-users/zsh/commit/10bdbd8b5b0b43445aff23dcd412f25cf6aa328a
libs_patches=(
    "https://sources.debian.org/data/main/z/zsh/5.9-8/debian/patches/cherry-pick-b62e91134-51723-migrate-pcre-module-to-pcre2.patch"
    "https://sources.debian.org/data/main/z/zsh/5.9-8/debian/patches/cherry-pick-10bdbd8b-51877-do-not-build-pcre-module-if-pcre2-config-is-not-found.patch"
)

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    # avoid hardcode PREFIX
    --enable-etcdir=/no-etc
    --enable-fndir=/no-functions
    --enable-scriptdir=/no-scripts
    --enable-site-fndir=/no-site-functions
    --enable-site-scriptdir=/no-site-scripts
    --enable-runhelpdir=/no-help

    # features
    --enable-cap
    --enable-maildir-support
    --enable-multibyte
    --enable-pcre
    --enable-zsh-secure-free
    --enable-unicode9
    --with-tcsetpgrp
    --with-term-lib=ncurses

    --disable-zshrc     # no global zshrc
    --disable-gdbm      # GDBM

    # modules
    --enable-dynamic    # dynamic modules

    --enable-static
)

libs_build() {
    # Fix compile with newer Clang. Remove in the next release
    # Ref: https://sourceforge.net/p/zsh/code/ci/ab4d62eb975a4c4c51dd35822665050e2ddc6918/
    export CFLAGS+=" -Wno-implicit-int"

    # needs patch supoort
    export PCRE_CONFIG="$PREFIX/bin/pcre2-config --prefix=$PREFIX"

    slogcmd ./Util/preconfig

    configure

    # static modules
    sed -i '/pcre/s/link=no/link=static/g' config.modules && # enable-pcre not working
    sed -i 's/link=dynamic/link=static/g' config.modules &&
    sed -i 's/load=no/load=yes/g' config.modules &&
    make prep

    # no common path for macOS and Linux
    make MODDIR=/no-zsh-modules

    pkgfile functions   -- make install.fns \
        datarootdir="$PREFIX/share/zsh"     \
        fndir="$PREFIX/share/zsh/functions"

    #pkgfile modules     -- make install.modules

    # test zsh after install modules and functions
    slogcmd ./Src/zsh -c "'zmodload zsh/pcre'" || die "build static zsh failed"

    cmdlet ./Src/zsh

    check zsh --version

    caveats << EOF
static built zsh @ $libs_ver

default modules are builtin

functions:

    cmdlets.sh install zsh/functions
    cmdlets.sh link share/zsh/functions ~/.zfunc

    then, add 'fpath=(~/.zfunc)' to ~/.zshrc
EOF
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
