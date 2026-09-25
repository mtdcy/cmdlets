# Just-In-Time Compiler (JIT) for the Lua programming language

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.1.1788856981 # @see brew:luajit.rb
libs_rev=2
libs_url=https://github.com/LuaJIT/LuaJIT/archive/c6ffc141a8762b41703f9287d63d93622a13dd8f.tar.gz
libs_sha=6e5fec07750add912e7c3eae0c194d24cd6d023714e1f04a0298a5b4819e4457

libs_deps=()

libs_args=(
    PREFIX="'$PREFIX'"

    # HOST
    HOST_CC="$HOSTCC"

    # TARGET
    STATIC_CC="$CC"
    TARGET_LD="$CC"
    TARGET_AR="$AR rcus"
    TARGET_STRIP="$STRIP"

    TARGET_CFLAGS="$CFLAGS $CPPFLAGS"
    TARGET_LDFLAGS="$LDFLAGS"

    BUILDMODE=static
)

# buildvm -m peobj
is_cygwin && libs_args+=(TARGET_SYS=Windows)

libs_build() {
    cmdlet.disclaim 2.1

    make "${libs_args[@]}"

    # ABIVER : 5.1
    cp -f src/libluajit.a src/libluajit-5.1.a

    cmdlet.pkginst libluajit \
            include/luajit-2.1  src/luajit.h \
                                src/luaconf.h \
                                src/lualib.h \
                                src/lua.hpp \
                                src/lauxlib.h \
                                src/lua.h \
            lib                 src/libluajit-5.1.a \
            lib/pkgconfig       etc/luajit.pc

    # install luajit as versioned and link to luajit
    cmdlet.install ./src/luajit luajit-$libs_ver luajit

    cmdlet.verify -- luajit -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
