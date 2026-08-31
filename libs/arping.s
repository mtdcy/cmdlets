# Portable impl of arping

# shellcheck disable=SC2034
libs_lic='GPL-2.0-or-later'
libs_ver=2.29
libs_rev=1
libs_url=https://github.com/ThomasHabets/arping/archive/refs/tags/arping-2.29.tar.gz
libs_sha=387955d6ba8eedcf242bb3784bebf8e40fad39703117e21e02cec12820990a5c
libs_dep=( libnet libpcap )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-shared
    --enable-static
)

libs_build() {
    slogcmd ./bootstrap.sh

    configure

    # error: redefinition of 'struct prctl_mm_map'
    #  musl-gcc: linux/prctl.h and sys/prctl.h both define prctl_mm_map
    is_musl && sed -i '/HAVE_LINUX_PRCTL_H/d' config.h

    # not build fuzz code
    make -C src arping

    cmdlet ./src/arping

    check arping --help
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
