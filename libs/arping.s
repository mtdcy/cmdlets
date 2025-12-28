# Portable impl of arping

# shellcheck disable=SC2034
libs_lic='GPL-2.0-or-later'
libs_ver=2.27
libs_url=https://github.com/ThomasHabets/arping/archive/refs/tags/arping-2.27.tar.gz
libs_sha=b54a1c628c1cd5222a787c739e544b0a456684aa1d4b04757ce2340cdd4eb506
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
