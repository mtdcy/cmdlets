# Utility for managing network connections

# shellcheck disable=SC2034
libs_lic='GPL-2.0+'
libs_ver=0.7.1
libs_url=https://downloads.sourceforge.net/project/netcat/netcat/0.7.1/netcat-0.7.1.tar.bz2
libs_sha=b55af0bbdf5acc02d1eb6ab18da2acd77a400bafd074489003f3df09676332bb
libs_dep=( )

# Fix running on Linux ARM64, using patch from Arch Linux ARM.
# https://sourceforge.net/p/netcat/bugs/51/
libs_patches=(
    https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/05ebc1439262e7622ba4ab0c15c2a3bad1ac64c4/extra/gnu-netcat/gnu-netcat-flagcount.patch
)

libs_args=(
)

libs_build() {
    slogcmd autoreconf -fiv

    configure

    make

    cmdlet ./src/netcat netcat nc

    check netcat --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
