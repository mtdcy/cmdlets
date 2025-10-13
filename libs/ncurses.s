# Text-based UI library
#
# shellcheck disable=SC2034

libs_name=ncurses
libs_lic='MIT'
libs_ver=6.5
libs_url=https://ftpmirror.gnu.org/gnu/ncurses/ncurses-$libs_ver.tar.gz
#https://ftpmirror.gnu.org/gnu/ncurses/ncurses-$libs_ver.tar.gz
libs_sha=136d91bc269a9a5785e5f9e980bc76ab57428f604ce3e5a5a90cebc767971cc6
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-pc-files
    --with-pkg-config-libdir="$PKG_CONFIG_PATH"
    --enable-widec # => ncursesw

    --disable-nls
    --disable-rpath

    # from homebrew:ncurses.rb
    --enable-sigwinch
    --enable-symlinks
    --with-gpm=no
    --without-ada

    # from macports:ncurses
    --enable-overwrite  # overwrite curses

    # from debian:/etc/terminfo/README
    #  => we are building static executable, cann't ship hardcoded prebuilts path into executables.
    --with-terminfo-dirs="/etc/terminfo:/lib/terminfo:/usr/share/terminfo"
    # /usr/share/terminfo is a common path for both Linux and macOS

    # don't install terminfo database, use system defaults
    #  => cause gettext check fail, see gettext.u.
    --with-default-terminfo-dir="/usr/share/terminfo"
    --disable-db-install

    # static without debug
    --without-shared
    --without-cxx-shared
    --disable-debug
    --without-manpages
)

libs_build() {
    configure &&

    make &&

    # make alias works better
    cp include/curses*.h include/ncursesw.h &&

    # install libraries
    pkgfile libncursesw:libncurses:libcurses     \
            include         include/ncurses*.h   \
                            include/curses*.h    \
                            include/term.h       \
                            include/termcap.h    \
                            include/eti.h        \
                            include/unctrl.h     \
                            include/term_entry.h \
            lib             lib/libncursesw*.a   \
            lib/pkgconfig   misc/ncursesw.pc     \
            &&

    pkgfile libncurses++w                        \
            include         c++/curses*.h        \
                            c++/etip.h           \
                            c++/cursslk.h        \
            lib             lib/libncurses++w*.a \
            lib/pkgconfig   misc/ncurses++w.pc   \
            &&

    pkgfile libformw:libform                     \
            include         include/form.h       \
            lib             lib/libform*.a       \
            lib/pkgconfig   misc/form*.pc        \
            &&

    pkgfile libpanelw:libpanel                   \
            include         include/panel.h      \
            lib             lib/libpanel*.a      \
            lib/pkgconfig   misc/panel*.pc       \
            &&

    pkgfile libmenuw:libmenu                     \
            include         include/menu.h       \
                            menu/eti.h           \
            lib             lib/libmenu*.a       \
            lib/pkgconfig   misc/menu*.pc        \
            &&

    cmdlet  progs/clear &&
    cmdlet  progs/tabs &&
    cmdlet  progs/tput &&
    cmdlet  progs/tset &&
    cmdlet  progs/tic &&
    cmdlet  progs/toe &&

    inspect_install make install

    # verify
    check tput
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
