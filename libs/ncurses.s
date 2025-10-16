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

    # libncurses with widec support
    --enable-widec 
    --disable-lib-suffixes

    # no old termcap and tinfo
    --disable-termcap

    --disable-nls
    --disable-rpath

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
    configure && make || return 1

    pkgfile libncurses  -- make install.libs &&

    # make and install terminfo database
    pkgfile terminfo    -- make install.data    \
            datarootdir="$PREFIX/share"         \
            datadir="$PREFIX/share"             \
            ticdir="$PREFIX/share/terminfo"     \
            &&

    cmdlet  ./progs/tic     tic infotocap captoinfo &&
    cmdlet  ./progs/tset    tset reset              &&
    cmdlet  ./progs/infocmp                         &&
    cmdlet  ./progs/clear                           &&
    cmdlet  ./progs/tabs                            &&
    cmdlet  ./progs/tput                            &&
    cmdlet  ./progs/toe                             &&

    # verify
    check tput
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
