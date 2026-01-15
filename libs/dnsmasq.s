# Lightweight DNS forwarder and DHCP server

# shellcheck disable=SC2034
libs_lic='GPL-2.0+'
libs_ver=2.92
libs_url=https://thekelleys.org.uk/dnsmasq/dnsmasq-2.92.tar.gz
libs_sha=fd908e79ff37f73234afcb6d3363f78353e768703d92abd8e3220ade6819b1e1
libs_dep=( libidn2 nettle )

is_linux && libs_dep+=( nftables )

libs_args=(
)

libs_build() {
    deparallelize

    # options
    COPTS="-DHAVE_LIBIDN2 -DHAVE_DNSSEC -DNO_I18N -DNO_DBUS -DNO_UBUS"
    if is_linux; then
        COPTS+=" -DHAVE_CONNTRACK"
    fi

    # Fix compilation on newer macOS versions.
    export CFLAGS+=" -D__APPLE_USE_RFC_3542"

    sed -i Makefile \
        -e '/^CFLAGS/d' \
        -e '/^LDFLAGS/d' \
        -e '/^PKG_CONFIG/d'

    # multiple definition of `cache_init'
    #  => why only cache_init is not defined as static
    hack.c.symbols src/dnsmasq.h cache_init

    make clean || true

    make PREFIX="'$PREFIX'" COPTS="'$COPTS'"

    cmdlet ./src/dnsmasq

    check dnsmasq --version

    if is_linux; then
        COPTS+=" -DNO_IPSET -DHAVE_NFTSET"

        make clean || true

        make PREFIX="'$PREFIX'" COPTS="'$COPTS'"

        cmdlet ./src/dnsmasq dnsmasq-nftset

        check dnsmasq-nftset --version
    fi
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
