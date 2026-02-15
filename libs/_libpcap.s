# Portable library for network traffic capture

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.10.6
libs_url=https://www.tcpdump.org/release/libpcap-1.10.6.tar.gz
libs_sha=872dd11337fe1ab02ad9d4fee047c9da244d695c6ddf34e2ebb733efd4ed8aa9
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

is_linux || libs_args+=( --disable-dbus )

# windows: needs Npcap drivers
is_mingw && libs_args+=( --with-pcap=null )

libs_build() {
    configure

    make.all

    # fix pcap-config
    sed -i pcap-config \
        -e 's/^static=.*/static=1/' \
        -e 's/^static_pcap_only=.*/static_pcap_only=1/' \

    pkgfile $libs_name -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
