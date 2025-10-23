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
    --enable-etcdir=/etc
    --enable-fndir=/usr/share/zsh/functions
    --enable-scriptdir=/usr/share/zsh/scripts
    --enable-site-fndir=/usr/share/zsh/site-functions
    --enable-site-scriptdir=/usr/share/zsh/site-scripts
    --enable-runhelpdir=/usr/share/zsh/help

    # features
    --enable-cap
    --enable-maildir-support
    --enable-multibyte
    --enable-pcre
    --enable-zsh-secure-free
    --enable-unicode9
    --with-tcsetpgrp

    DL_EXT=bundle

    #--disable-dynamic  # modules
)

libs_build() {
    # Fix compile with newer Clang. Remove in the next release
    # Ref: https://sourceforge.net/p/zsh/code/ci/ab4d62eb975a4c4c51dd35822665050e2ddc6918/
    export CFLAGS+=" -Wno-implicit-int"

    configure

    make

    pkgfile functions   -- make install.fns

    pkgfile modules     -- make install.modules

    cmdlet ./Src/zsh

    check zsh --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
