# Implementation of malloc emphasizing fragmentation avoidance

# shellcheck disable=SC2034
libs_lic='BSD-2-Clause'
libs_ver=5.3.1
libs_url=https://github.com/jemalloc/jemalloc/releases/download/5.3.1/jemalloc-5.3.1.tar.bz2
libs_sha=3826bc80232f22ed5c4662f3034f799ca316e819103bdc7bb99018a421706f92
libs_dep=( )

libs_args=(
    --disable-debug

    --with-jemalloc-prefix=

    --disable-shared
    --enable-static
)

is_linux && is_arm64 && libs_args+=( --with-lg-page=16 )

libs_build() {

    configure

    make

    # Do not run checks with Xcode 15, they fail because of
    # overly eager optimization in the new compiler:
    # https://github.com/jemalloc/jemalloc/issues/2540
    # Reported to Apple as FB13209585
    #make check

    pkgfile libjemalloc -- make install_include install_lib install_lib_pc

    cmdlet ./bin/jeprof
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
