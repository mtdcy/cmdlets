# Netperf is a benchmark that can be used to measure the performance of many different types of networking.

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=2.7.0
libs_url=https://github.com/HewlettPackard/netperf/archive/refs/tags/netperf-2.7.0.tar.gz
libs_sha=4569bafa4cca3d548eb96a486755af40bd9ceb6ab7c6abd81cc6aa4875007c4e
libs_dep=( )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-debug
    --disable-doxygen-doc

    --disable-shared
    --enable-static
)

# fix 'error: cannot guess build type'
is_darwin || libs_args+=( --build="$(uname -m)-unknown-linux-gnu" )

libs_build() {
    apply_c89_flags

    configure

    make

    cmdlet ./src/netperf

    check netperf -V
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
