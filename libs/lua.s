# Powerful, lightweight programming language

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=5.5.0
libs_url=https://www.lua.org/ftp/lua-5.5.0.tar.gz
libs_sha=57ccc32bbbd005cab75bcc52444052535af691789dba2b9016d5c50640d68b3d

libs_deps=( readline )

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
    elif is_mingw; then
        # mingw target build shared dll
        #make -C src mingw

        make -C src LUA_T=lua.exe lua.exe
	    make -C src LUAC_T=luac.exe luac.exe
        LIBS=( -llua )
    else
        make -C src linux
        LIBS=( -llua -lm -ldl )
    fi

    cmdlet.pkgconf lua.pc "${LIBS[@]}" readline

    cmdlet.pkginst liblua                                \
        src/{lua.h,luaconf.h,lualib.h,lauxlib.h,lua.hpp} \
        src/liblua.a                                     \
        lua.pc

    for x in lua luac; do
        cmdlet.install "src/$x"
    done

    cmdlet.check lua -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
