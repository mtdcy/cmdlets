# Text-based UI library
#
# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=6.6
libs_url=https://ftpmirror.gnu.org/gnu/ncurses/ncurses-$libs_ver.tar.gz
#https://ftpmirror.gnu.org/gnu/ncurses/ncurses-$libs_ver.tar.gz
libs_sha=355b4cbbed880b0381a04c46617b7656e362585d52e9cf84a67e2009b749ff11

is_mingw && libs_deps+=(libgnurx)

libs_patches=(
    # do not leak build-time LDFLAGS into the pkgconfig files:
    # https://bugs.archlinux.org/task/68523
    https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-ncurses/ncurses-6.3-pkgconfig.patch
)

FALLBACKS="linux,screen,screen-256color,xterm,xterm-256color,vt100"

# build a simple and fast ncurses library
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-normal
    --with-pkg-config
    --enable-pc-files
    --with-pkg-config-libdir="$PKG_CONFIG_PATH"

    # libncursesw
    --enable-widec
    --disable-lib-suffixes

    # terminfo
    # The system's tic program is used to install the terminal database, even for cross-compiles.
    --with-fallbacks="$FALLBACKS"   # builtin terminfo
    #--disable-database             # fallback still needs database
    --disable-db-install            # do not install database
    --enable-home-terminfo          # search ~/.terminfo for terminfo

    # terminfo(ncurses) vs termcap(obsolete)
    #  => Modern systems predominantly use terminfo
    # https://invisible-island.net/ncurses/INSTALL.html#CONFIGURING-FALLBACK-ENTRIES
    # pure-terminfo mode, no termcap => makes the ncurses library smaller and faster
    --disable-termcap           # enable termcap for fallbacks => needs infocmp

    # legacy: -lcurses
    --disable-overwrite         # put headers in subdir, omit link to -lcurses

    # disabled features
    --disable-nls
    --with-gpm=no
    --without-ada
    --without-tests
    --without-manpages

    # static without debug
    --without-shared
    --without-cxx-shared
    --disable-debug
)

# 现代 Ncurses 源码在检测到 --host=*mingw* 时，会自动开启对 Windows 控制台和 Windows 10+ 虚拟终端（Virtual Terminal）的支持。
if is_mingw; then
    libs_args+=(
        --build=$(uname -m)-linux-gnu
        --host=$(uname -m)-w64-mingw32
        --disable-symlinks
    )
else
    libs_args+=(
        --enable-symlinks
    )
fi

libs_build() {
    #1. build unix/host tools tic/infocmp
    (   
        mkdir -pv .host && cd .host
        unset CC CXX CPP CFLAGS CXXFLAGS LD LDFLAGS
        unset PKG_CONFIG PKG_CONFIG_PATH PKG_CONFIG_LIBDIR
        slogcmd ../configure --without-ada --disable-overwrite --with-normal
        make PROGS="'tic infocmp'"
        cd ..
    ) || return 1

    #2. build for targets
    if is_mingw; then
        # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-ncurses/PKGBUILD
        # It passes X_OK to access() on Windows which isn't supported with ucrt
        CFLAGS+=" -D__USE_MINGW_ACCESS"

        if libs.func.exists time.h nanosleep; then
            export gl_cv_func_nanosleep=yes
            export ac_cv_func_nanosleep=yes
        fi
    fi

    export CFLAGS+=" -DNCURSES_STATIC"

    # build with fallback.c
    configure \
        --with-tic-path="$PWD/.host/progs/tic" \
        --with-infocmp="$PWD/.host/progs/infocmp"

    make

    # fix ncurses6-config
    #  1. no rpath things
    sed -i misc/ncurses-config \
        -e 's/^RPATH_LIST=.*/RPATH_LIST=/'

    cmdlet.pkgconf misc/ncurses.pc -DNCURSES_STATIC

    cmdlet.pkgfile libncurses -- make install.libs

    #               source          target  links...
    cmdlet.install  ./progs/infocmp
    cmdlet.install  ./progs/tic     tic     infotocap captoinfo
    cmdlet.install  ./progs/tset    tset    reset
    cmdlet.install  ./progs/clear
    cmdlet.install  ./progs/tabs
    cmdlet.install  ./progs/tput
    cmdlet.install  ./progs/toe

    # verify
    check tput
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
