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

    --disable-nls

    # from homebrew:ncurses.rb
    --enable-sigwinch
    --enable-symlinks
    --with-gpm=no
    --without-ada

    # from macports:ncurses
    --enable-overwrite  # overwrite curses

    # we are building static executable, cann't ship hardcoded prebuilts path into executables.
    #
    # terminfo search dirs
    #  check with `infocmp -D'
    #  override with env TERMINFO
    #
    # from debian:/etc/terminfo/README
    --with-terminfo-dirs="/etc/terminfo:/lib/terminfo:/usr/share/terminfo"
    # /usr/share/terminfo is a common path for both Linux and macOS
    --with-default-terminfo-dir="/usr/share/terminfo"

    # --with-fallbacks
    --without-database
    --enable-termcap # for fallbacks support

    # static without debug
    --without-shared
    --without-cxx-shared
    --disable-debug
    --without-manpages
)

libs_build() {
    # install tic & infocmp first for fallbacks support
    #  https://stackoverflow.com/questions/76290814/compile-ncurses-disable-database-why-nc-fallback-undefined
    #  https://invisible-island.net/ncurses/INSTALL.html#CONFIGURING-FALLBACK-ENTRIES
    configure && make PROGS="'tic infocmp'"

    # prepare fallbacks
    ./ncurses/tinfo/MKfallback.sh \
        "$TERMINFO"               \
        ./misc/terminfo.src       \
        ./progs/tic               \
        ./progs/infocmp           \
        linux xterm               \
        > ncurses/fallback.c

    make

    pkgfile libncurses  -- make install.libs

    #       source          target  links...
    cmdlet  ./progs/tic     tic     infotocap captoinfo
    cmdlet  ./progs/infocmp
    cmdlet  ./progs/tset    tset    reset
    cmdlet  ./progs/clear
    cmdlet  ./progs/tabs
    cmdlet  ./progs/tput
    cmdlet  ./progs/toe

    # verify
    check tput
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
