# Implementation of malloc emphasizing fragmentation avoidance

# shellcheck disable=SC2034
libs_targets=(linux darwin)

libs_lic='BSD-2-Clause'
libs_ver=5.4.0
libs_rev=1
libs_url=https://github.com/jemalloc/jemalloc/releases/download/5.4.0/jemalloc-5.4.0.tar.bz2
libs_sha=200776fac271093e7c2f21edd6d62657ecd2be578d9328633f2a86bfa6ef4f1d
libs_dep=()

libs_args=(
    --disable-debug

    --with-jemalloc-prefix=

    --disable-shared
    --enable-static
)

is_linux && is_arm64 && libs_args+=(--with-lg-page=16)

libs_build() {
    # since 5.4.0 : fix error: invalid conversion from 'int' to 'char*'
    libs.requires -fpermissive

    configure

    make

    # Do not run checks with Xcode 15, they fail because of
    # overly eager optimization in the new compiler:
    # https://github.com/jemalloc/jemalloc/issues/2540
    # Reported to Apple as FB13209585
    #make check

    cmdlet.pkgfile libjemalloc -- make install_include install_lib install_lib_pc

    cmdlet.install ./bin/jeprof
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
