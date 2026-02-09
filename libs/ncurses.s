# Text-based UI library
#
# shellcheck disable=SC2034

libs_name=ncurses
libs_lic='MIT'
libs_ver=6.6
libs_url=https://ftpmirror.gnu.org/gnu/ncurses/ncurses-$libs_ver.tar.gz
#https://ftpmirror.gnu.org/gnu/ncurses/ncurses-$libs_ver.tar.gz
libs_sha=355b4cbbed880b0381a04c46617b7656e362585d52e9cf84a67e2009b749ff11
libs_dep=()

# build a simple and fast ncurses library
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --disable-overwrite         # put headers in subdir, omit link to -lcurses

    # --datadir                 # terminfo location

    # terminfo(ncurses) vs termcap(obsolete)
    #  => Modern systems predominantly use terminfo
    # https://invisible-island.net/ncurses/INSTALL.html#CONFIGURING-FALLBACK-ENTRIES
    # pure-terminfo mode, no termcap => makes the ncurses library smaller and faster
    --disable-termcap           # enable termcap for fallbacks => needs infocmp
    --without-fallbacks         # no fallback to termcap
    # The system's tic program is used to install the terminal database, even for cross-compiles.
    --without-database          # terminfo database

    # libncurses with widec support
    --enable-widec
    --disable-lib-suffixes

    # misc
    --enable-term-driver
    --enable-sp-funcs
    --enable-pc-files
    --with-pkg-config-libdir="$PKG_CONFIG_PATH"

    # disabled features
    --disable-nls
    --with-gpm=no
    --without-ada

    # static without debug
    --without-shared
    --without-cxx-shared
    --disable-debug
    --without-manpages
)

if is_mingw; then
    libs_args+=(
        --disable-home-terminfo         # drop ~/.terminfo from terminfo search-path
        --disable-symlinks
    )
 else
    # *nix system: avoid hardcoded PREFIX
    libs_args+=(
        # we are building static executable, cann't ship hardcoded prebuilts path into executables.
        #
        # terminfo search dirs, override with env TERMINFO
        #
        # from debian:/etc/terminfo/README
        --with-terminfo-dirs="/etc/terminfo:/lib/terminfo:/usr/share/terminfo"
        # /usr/share/terminfo is a common path for both Linux and macOS
        --with-default-terminfo-dir="/usr/share/terminfo"
    )
fi

libs_build() {
    # mingw
    if is_mingw; then
        # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-ncurses/PKGBUILD
        # It passes X_OK to access() on Windows which isn't supported with ucrt
        CFLAGS+=" -D__USE_MINGW_ACCESS"
        # nanosleep is only defined in pthread library
        export cf_cv_func_nanosleep=no


        export BUILD_EXEEXT="$_BINEXT"
        export PATH_SEPARATOR=";"

        # EXT not working for these scripts
        sed -i ncurses/tinfo/MKcaptab.sh \
            -i ncurses/tinfo/MKuserdefs.sh \
            -e "s/\<make_hash\>/make_hash$_BINEXT/g" || die
    fi

    configure

    make

    # fix ncurses6-config
    #  1. no rpath things
    sed -i misc/ncurses-config \
        -e 's/^RPATH_LIST=.*/RPATH_LIST=/'

    pkgconf misc/ncurses.pc -DNCURSES_STATIC

    pkgfile libncurses  -- make install.libs

    #       source          target  links...
    cmdlet  ./progs/tic     tic     infotocap captoinfo
    cmdlet  ./progs/tset    tset    reset
    cmdlet  ./progs/clear
    cmdlet  ./progs/tabs
    cmdlet  ./progs/tput
    cmdlet  ./progs/toe

    # verify
    check tput
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
