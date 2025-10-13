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

    # no termcap and tinfo
    --disable-termcap

    # from homebrew:ncurses.rb
    --enable-sigwinch
    --enable-symlinks
    --with-gpm=no
    --without-ada

    # from macports:ncurses
    --enable-overwrite  # overwrite curses

    # terminfo search dirs: `infocmp -D' or set TERMINFO
    #  => we are building static executable, cann't ship hardcoded prebuilts path into executables.
    #
    # from debian:/etc/terminfo/README
    --with-terminfo-dirs="/etc/terminfo:/lib/terminfo:/usr/share/terminfo"
    # /usr/share/terminfo is a common path for both Linux and macOS
    --with-default-terminfo-dir="/usr/share/terminfo"

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
    library libncursesw:libncurses:libcurses     \
            include         include/ncurses*.h   \
                            include/curses*.h    \
                            include/term.h       \
                            include/eti.h        \
                            include/unctrl.h     \
                            include/term_entry.h \
            lib             lib/libncursesw*.a   \
            lib/pkgconfig   misc/ncursesw.pc     \
            &&

    library libncurses++w                        \
            include         c++/curses*.h        \
                            c++/etip.h           \
                            c++/cursslk.h        \
            lib             lib/libncurses++w*.a \
            lib/pkgconfig   misc/ncurses++w.pc   \
            &&

    library libformw:libform                     \
            include         include/form.h       \
            lib             lib/libform*.a       \
            lib/pkgconfig   misc/form*.pc        \
            &&

    library libpanelw:libpanel                   \
            include         include/panel.h      \
            lib             lib/libpanel*.a      \
            lib/pkgconfig   misc/panel*.pc       \
            &&

    library libmenuw:libmenu                     \
            include         include/menu.h       \
                            menu/eti.h           \
            lib             lib/libmenu*.a       \
            lib/pkgconfig   misc/menu*.pc        \
            &&

    cmdlet  ./progs/tic     tic infotocap captoinfo &&
    cmdlet  ./progs/tset    tset reset              &&
    cmdlet  ./progs/infocmp                         &&
    cmdlet  ./progs/clear                           &&
    cmdlet  ./progs/tabs                            &&
    cmdlet  ./progs/tput                            &&
    cmdlet  ./progs/toe                             &&

    # ncurses-config --terminfo-dirs
    cmdlet  ./misc/ncurses-config ncursesw-config ncurses-config &&

    #inspect_install make install

    # make and install terminfo database
    make install.data                   \
        datarootdir="$PREFIX/share"     \
        datadir="$PREFIX/share"         \
        ticdir="$PREFIX/share/terminfo" \
        &&

    pkgfile terminfo share/tabset share/terminfo    &&


    # verify
    check tput
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
