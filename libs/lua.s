# Powerful, lightweight programming language

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=5.4.8
libs_url=https://www.lua.org/ftp/lua-5.4.8.tar.gz
libs_sha=4f18ddae154e793e46eeab727c59ef1c0c0c2b744e7b94219710d76f530629ae
libs_dep=( readline )

libs_args=(
)

libs_build() {
    hack.makefile src/Makefile CC CFLAGS CPPFLAGS LDFLAGS

    # no CPPFLAGS in Makefile
    export CFLAGS="$CFLAGS $CPPFLAGS"

    # handle static readline
    READLINE="$($PKG_CONFIG --cflags --libs-only-l readline)"
    sed -i src/Makefile \
        -e "s%-lreadline%$READLINE%g"

    if is_darwin; then
        make -C src macos
        LIBS=( -llua -lm )
    else
        make -C src linux-readline
        LIBS=( -llua -lm -ldl )
    fi

    pkgconf lua.pc "${LIBS[@]}"               \
        $($PKG_CONFIG --cflags readline)      \
        $($PKG_CONFIG --libs-only-l readline) \

    pkginst liblua                                                   \
                    src/{lua.h,luaconf.h,lualib.h,lauxlib.h,lua.hpp} \
                    src/liblua.a                                     \
                    lua.pc

    for x in lua luac; do
        cmdlet.install "src/$x"
    done

    cmdlet.check lua -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
