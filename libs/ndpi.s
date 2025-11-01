# Deep Packet Inspection (DPI) library

# shellcheck disable=SC2034
libs_lic='LGPLv3+'
libs_ver=4.14
libs_url=https://github.com/ntop/nDPI/archive/refs/tags/4.14.tar.gz
libs_sha=954135ee14ad6bd74a78a10db560b534b8f2083ad0615f5c1a2c376fff0301e0
libs_dep=( json-c libpcap )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --with-only-libndpi

    --disable-shared
    --enable-static
)

libs_build() {
    slogcmd ./autogen.sh

    configure

    # fix: static only
    sed -i src/lib/Makefile \
        -e '/^NDPI_LIBS/s/\$(NDPI_LIB_SHARED)//' \
        -e '/NDPI_LIB_SHARED_BASE/d'

    make.all

    pkgfile libndpi -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
