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

    CC="'$CC'"
    CFLAGS="'$CFLAGS'"
    LDFLAGS="'$LDFLAGS'"

    BUILDMODE=static
)

libs_build() {
    cmdlet.disclaim 2.1

    make "${libs_args[@]}"

    cmdlet.pkgfile libluajit -- make install "${libs_args[@]}"

    # install as versioned and link to luajit
    cmdlet.install ./src/luajit luajit-$libs_ver luajit

    cmdlet.verify -- luajit -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
