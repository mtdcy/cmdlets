# nftables replaces the popular {ip,ip6,arp,eb}tables.
# libnftables, the high-level userspace library that includes support for JSON.

# shellcheck disable=SC2034
libs_lic='GPLv2+'
libs_ver=1.1.5
libs_url=https://www.netfilter.org/projects/nftables/files/nftables-1.1.5.tar.xz
libs_sha=
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
    depends_on is_linux

    # configure:
    #  fix static libedit with -lncurses
    export LIBS="-lncurses"

    configure

    make

    pkgfile $libs_name -- make install sbin_PROGRAMS=

    cmdlet ./src/nft

    check nft --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
