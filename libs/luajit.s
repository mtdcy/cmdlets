# Just-In-Time Compiler (JIT) for the Lua programming language

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.1
libs_url=https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v$libs_ver.ROLLING.tar.gz
libs_sha=31d7a4853df4c548bf91c13d3b690d19663d4c06ae952b62606c8225d0b410ad
libs_dep=()

libs_args=(
    PREFIX="'$PREFIX'"

    CC="'$CC'"
    CFLAGS="'$CFLAGS'"
    LDFLAGS="'$LDFLAGS'"

    BUILDMODE=static
)

libs_build() {
    make "${libs_args[@]}" &&

    pkgfile libluajit -- make install "${libs_args[@]}" &&

    # install as versioned and link to luajit
    cmdlet ./src/luajit luajit-$libs_ver luajit &&

    check luajit -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
