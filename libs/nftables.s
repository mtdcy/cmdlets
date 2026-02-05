# nftables replaces the popular {ip,ip6,arp,eb}tables.
# libnftables, the high-level userspace library that includes support for JSON.

# no auto update
libs_stable=1

# shellcheck disable=SC2034
libs_lic='GPLv2+'
libs_ver=1.0.6.1
libs_url=https://www.netfilter.org/projects/nftables/files/nftables-$libs_ver.tar.xz
libs_sha=bef0c9cfdca5f8b988957046c2cb33ef9869730593da0eacae4748201acf1116
libs_dep=( gmp jansson libedit libnetfilter ) # libxtables

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --with-json
    --without-xtables # Use libxtables for iptables interaction

    --disable-debug
    --disable-man-doc

    --disable-shared
    --enable-static
)

libs_build() {

    # disclaim non-stable releases
    cmdlet.disclaim 1.1.5 1.1.6

    # configure:
    #  fix static libedit with -lncurses
    export LIBS="-lncurses"

    configure

    # multiple definition of `cache_init' vs dnsmasq
    hack.c.symbols include/cache.h cache_init

    make

    pkgconf libnftables.pc -lnftables -lgmp -ljansson -ledit -lmnl -lnftnl

    cmdlet.pkgfile libnftables -- make.install sbin_PROGRAMS=

    cmdlet.install ./src/nft

    cmdlet.check nft --version
}

libs.depends is_linux

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
