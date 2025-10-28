# Portable impl of arping

# shellcheck disable=SC2034
libs_lic='GPL-2.0-or-later'
libs_ver=2.26
libs_url=https://github.com/ThomasHabets/arping/archive/refs/tags/arping-2.26.tar.gz
libs_sha=58e866dce813d848fb77d5e5e0e866fb4a02b55bab366a0d66409da478ccb12f
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

    # not build fuzz code
    make -C src arping

    cmdlet ./src/arping

    check arping --help
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
