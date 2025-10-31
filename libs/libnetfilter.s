# netfilter libraries

# shellcheck disable=SC2034
libs_lic='LGPLv2+'

# use nftables version as pkgvern
libs_ver=1.1.5
libs_url=https://www.netfilter.org/projects/nftables/files/changes-nftables-1.1.5.txt
libs_sha=c3f5bb2a25e1b5c04a9b4ebbe5e7c37efa95d07998d358890006434d18fcfcb0
libs_dep=( )

libs_resources=(
    # libmnl is a minimalistic user-space library oriented to Netlink developers.
    https://www.netfilter.org/projects/libmnl/files/libmnl-1.0.5.tar.bz2
    # libnftnl is a userspace library providing a low-level netlink programming interface (API) to the in-kernel nf_tables subsystem.
    https://www.netfilter.org/projects/libnftnl/files/libnftnl-1.3.0.tar.xz
    # libnfnetlink is the low-level library for netfilter related kernel/userspace communication.
    https://www.netfilter.org/projects/libnfnetlink/files/libnfnetlink-1.0.2.tar.bz2
    # libnetfilter_acct is the userspace library providing interface to extended accounting infrastructure.
    https://www.netfilter.org/projects/libnetfilter_acct/files/libnetfilter_acct-1.0.3.tar.bz2
    # ibnetfilter_log is a userspace library providing interface to packets that have been logged by the kernel packet filter.
    https://www.netfilter.org/projects/libnetfilter_log/files/libnetfilter_log-1.0.2.tar.bz2
    # libnetfilter_queue is a userspace library providing an API to packets that have been queued by the kernel packet filter.
    https://www.netfilter.org/projects/libnetfilter_queue/files/libnetfilter_queue-1.0.5.tar.bz2
    # libnetfilter_conntrack is a userspace library providing a programming interface (API) to the in-kernel connection tracking state table.
    https://www.netfilter.org/projects/libnetfilter_conntrack/files/libnetfilter_conntrack-1.1.0.tar.xz
    # libnetfilter_cttimeout is the userspace library that provides the programming interface to the fine-grain connection tracking timeout infrastructure.
    https://www.netfilter.org/projects/libnetfilter_cttimeout/files/libnetfilter_cttimeout-1.0.1.tar.bz2
    # libnetfilter_cthelper is the userspace library that provides the programming interface to the user-space helper infrastructure available since Linux kernel 3.6.
    https://www.netfilter.org/projects/libnetfilter_cthelper/files/libnetfilter_cthelper-1.0.1.tar.bz2
)

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-shared
    --enable-static
)

libs_build() {
    depends_on is_linux

    visibility.hidden

    libnetfilter() {
        (
            cd "$1"-*
            configure
            pkgfile "$1@$2" -- make install
        ) || die "build $1 failed"
    }

    hack.c.symbols libnetfilter_conntrack-1.1.0/include/internal/internal.h __abi_breakage
    hack.c.symbols libnftnl-1.3.0/include/utils.h __abi_breakage

    libnetfilter libmnl 1.0.5
    libnetfilter libnftnl  1.3.0
    libnetfilter libnfnetlink  1.0.2
    libnetfilter libnetfilter_acct 1.0.3
    libnetfilter libnetfilter_log 1.0.2
    libnetfilter libnetfilter_queue 1.0.5
    libnetfilter libnetfilter_conntrack 1.1.0
    libnetfilter libnetfilter_cttimeout 1.0.1
    libnetfilter libnetfilter_cthelper 1.0.1
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
