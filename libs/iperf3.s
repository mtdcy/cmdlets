# Update of iperf: measures TCP, UDP, and SCTP bandwidth
#
# shellcheck disable=SC2034

libs_lic='BSD-3-Clause'
libs_ver=3.18
libs_url=https://github.com/esnet/iperf/releases/download/$libs_ver/iperf-$libs_ver.tar.gz
libs_sha=c0618175514331e766522500e20c94bfb293b4424eb27d7207fb427b88d20bab
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --disable-shared
    --enable-static
)

libs_build() {
    configure &&

    make &&

    # check
    #make check &&

    cmdlet ./src/iperf3 &&

    # verify
    check iperf3
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
