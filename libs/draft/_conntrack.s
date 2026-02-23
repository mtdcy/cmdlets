# nftables replaces the popular {ip,ip6,arp,eb}tables.
# libnftables, the high-level userspace library that includes support for JSON.

# shellcheck disable=SC2034
libs_lic='GPLv2+'
libs_ver=1.4.8
libs_url=https://www.netfilter.org/projects/conntrack-tools/files/conntrack-tools-1.4.8.tar.xz
libs_sha=
libs_dep=( libnetfilter )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking


    --disable-debug
    --disable-man-doc

    --disable-shared
    --enable-static
)

libs_build() {
    depends_on is_linux

    configure

    make

}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
