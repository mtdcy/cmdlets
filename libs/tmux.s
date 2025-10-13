# Terminal multiplexer
# shellcheck disable=SC2034
libs_name=tmux
libs_lic="ISC"
libs_ver=3.5a
libs_url=https://github.com/tmux/tmux/releases/download/$libs_ver/tmux-$libs_ver.tar.gz
libs_sha=16216bd0877170dfcc64157085ba9013610b12b082548c7c9542cc0103198951
libs_dep=( ncurses libevent )

libs_args=(
    --enable-sixel
    --sysconfdir=/etc

    # utf8proc not ready
    --disable-utf8proc

    # default TERM
    --with-TERM="screen-256color"
)

is_darwin || libs_args+=( --enable-static )

libs_build() {
    export TERMINFO="$PREFIX/share/terminfo"

    configure && make || return 1

    cmdlet tmux &&

    check tmux -V
}
# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
