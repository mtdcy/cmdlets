# Traceroute implementation using TCP packets

# shellcheck disable=SC2034
libs_lic='GPL-2.0-only'
libs_ver=1.5beta7
libs_url=https://github.com/mct/tcptraceroute/archive/refs/tags/tcptraceroute-1.5beta7.tar.gz
libs_sha=57fd2e444935bc5be8682c302994ba218a7c738c3a6cae00593a866cd85be8e7
libs_dep=( libpcap libnet )

# Call `pcap_lib_version()` rather than access `pcap_version` directly
# upstream issue: https://github.com/mct/tcptraceroute/issues/5
libs_patches=(
    https://github.com/mct/tcptraceroute/commit/3772409867b3c5591c50d69f0abacf780c3a555f.patch?full_index=1
)

libs_args=(
    --with-libnet="'$PREFIX'"
    --with-libpcap="'$PREFIX'"
)

is_linux && libs_args+=( --enable-static )

libs_build() {
    slogcmd autoreconf -fiv

    configure

    make

    cmdlet ./tcptraceroute

    check tcptraceroute --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
