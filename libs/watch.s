# Executes a program periodically, showing output fullscreen

# shellcheck disable=SC2034
libs_lic="GPLv2+|LGPLv2.1+"
libs_ver=4.0.7
libs_url=https://gitlab.com/procps-ng/procps/-/archive/v$libs_ver/procps-v$libs_ver.tar.bz2
libs_sha=707d4d43c78b1ff9d0286a4839465e78fa1a82896ec97d3508765b31a808b4b2
libs_dep=( ncurses )

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --disable-nls

    --enable-watch8bit

    --disable-shared
    --enable-static
)

# from homebrew
is_darwin && libs_args+=( --disable-pidwait )

is_darwin && libs_patches=(
    # guard `SIGPOLL` to fix build on macOS, upstream pr ref, https://gitlab.com/procps-ng/procps/-/merge_requests/246
    #https://gitlab.com/procps-ng/procps/-/commit/2dc340e47669e0b0df7f71ff082e05ac5fa36615.diff
)

libs_build() {
    # procps-ng search for ncursesw instead of ncurses
    NCURSES_CFLAGS="$($PKG_CONFIG --cflags ncurses)"
    NCURSES_LIBS="$($PKG_CONFIG --libs-only-l ncurses)"

    export NCURSES_CFLAGS NCURSES_LIBS

    # write version
    echo "$libs_ver" > .tarball-version

    rm autogen.sh # force autoreconf

    bootstrap

    configure

    make src/watch

    cmdlet.install src/watch

    cmdlet.check watch --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
