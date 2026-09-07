# Powerful, lightweight programming language

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=5.5.1
libs_url=https://www.lua.org/ftp/lua-5.5.1.tar.gz
libs_sha=1c4b4068d67061f2a2231ad2b5422e77acea1487ea9890f6320af614f4373dce

libs_deps=(readline)

libs_args=(
    CC="$CC"
    # no CPPFLAGS in Makefile
    CFLAGS="$CFLAGS $CPPFLAGS"
    CPPFLAGS="$CPPFLAGS"
    LDFLAGS="$LDFLAGS"
)

libs_build() {
    # handle static readline
    READLINE="$($PKG_CONFIG --cflags --libs-only-l readline)"

    # static readline
    sed -i src/Makefile \
        -e "s%-lreadline%$READLINE%g"

    if is_darwin; then
        make -C src macos "${libs_args[@]}"
        LIBS=(-llua -lm)
    elif is_mingw || is_cygwin; then
        # mingw target build shared dll
        #make -C src mingw

        make -C src LUA_T=lua.exe lua.exe "${libs_args[@]}"
        make -C src LUAC_T=luac.exe luac.exe "${libs_args[@]}"
        LIBS=(-llua)
    else
        make -C src linux "${libs_args[@]}"
        LIBS=(-llua -lm -ldl)
    fi

    cmdlet.pkgconf lua.pc "${LIBS[@]}" readline

    cmdlet.pkginst liblua \
        src/{lua.h,luaconf.h,lualib.h,lauxlib.h,lua.hpp} \
        src/liblua.a \
        lua.pc

    for x in lua luac; do
        cmdlet.install "src/$x"
    done

    cmdlet.check lua -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
