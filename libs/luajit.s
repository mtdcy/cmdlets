# Just-In-Time Compiler (JIT) for the Lua programming language

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.1
libs_url=https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v$libs_ver.ROLLING.tar.gz
libs_sha=31d7a4853df4c548bf91c13d3b690d19663d4c06ae952b62606c8225d0b410ad
libs_dep=()

libs_args=(
)

libs_build() {
    sed -e "s%/usr/local%$PREFIX%" \
        -i Makefile &&

    sed -e "/^CC=/d" \
        -e 's/^BUILDMODE=.*$/BUILDMODE=static/' \
        -i src/Makefile &&

    make &&

    library lua:lua-$libs_ver \
            include/lua     src/{lauxlib.h,lua.h,lua.hpp,luaconf.h,luajit.h,lualib.h} \
            lib             src/libluajit.a \
            lib/pkgconfig   etc/luajit.pc &&

    cmdlet  ./src/luajit    luajit luajit-$libs_ver &&

    check luajit -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
