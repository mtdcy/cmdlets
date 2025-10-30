# Lightweight DNS forwarder and DHCP server

# shellcheck disable=SC2034
libs_lic='GPL-2.0+'
libs_ver=2.91
libs_url=https://thekelleys.org.uk/dnsmasq/dnsmasq-2.91.tar.gz
libs_sha=2d26a048df452b3cfa7ba05efbbcdb19b12fe7a0388761eb5d00938624bd76c8
libs_dep=( libidn2 nftables )

libs_args=(
)

libs_build() {
    deparallelize

    # options
    #COPTS="-DHAVE_NFTSET"

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
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
