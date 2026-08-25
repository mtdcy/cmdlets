# Update of iperf: measures TCP, UDP, and SCTP bandwidth
#
# shellcheck disable=SC2034

libs_lic='BSD-3-Clause'
libs_ver=3.18
libs_rev=1
libs_url=https://github.com/esnet/iperf/releases/download/$libs_ver/iperf-$libs_ver.tar.gz
libs_rev=1
libs_sha=c0618175514331e766522500e20c94bfb293b4424eb27d7207fb427b88d20bab
libs_dep=(openssl)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-openssl="'$PREFIX'"

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    # check
    #make check &&
    cmdlet.install ./src/iperf3

    # verify
    cmdlet.check iperf3
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
