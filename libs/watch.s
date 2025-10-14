# Executes a program periodically, showing output fullscreen

# shellcheck disable=SC2034
libs_lic="GPL-2.0-or-later"
libs_ver=4.0.5
libs_url=https://gitlab.com/procps-ng/procps/-/archive/v$libs_ver/procps-v$libs_ver.tar.bz2
libs_sha=7e4b385e8f3e426089f3bb04e3bf150c710b875bd005474f034486b2379ce221
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

# guard `SIGPOLL` to fix build on macOS, upstream pr ref, https://gitlab.com/procps-ng/procps/-/merge_requests/246
is_darwin && libs_patches=(
    https://gitlab.com/procps-ng/procps/-/commit/2dc340e47669e0b0df7f71ff082e05ac5fa36615.diff
)

libs_build() {
    slogcmd autoreconf -fiv || return 1

    configure  || return 2

    make src/watch &&

    cmdlet src/watch &&

    check watch --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
