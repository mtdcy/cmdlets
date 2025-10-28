# Portable library for network traffic capture

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.10.5
libs_url=https://www.tcpdump.org/release/libpcap-1.10.5.tar.gz
libs_sha=37ced90a19a302a7f32e458224a00c365c117905c2cd35ac544b6880a81488f0
libs_dep=( )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --enable-ipv6

    --disable-universal
    --disable-debug

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    sed -i Makefile \
        -e '/^install:/s/pcap-config//' \
        -e '/pcap-config/d'

    pkgfile $libs_name -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
