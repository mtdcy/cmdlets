# GNU utilities for networking

libs_targets=( ! windows )

# shellcheck disable=SC2034
libs_lic='GPL-3.0+'
libs_ver=2.8
libs_url=(
    https://mirrors.ustc.edu.cn/gnu/inetutils/inetutils-2.8.tar.gz
    https://ftpmirror.gnu.org/gnu/inetutils/inetutils-2.8.tar.gz
)
libs_sha=57b3cf4f77555992881e5ba2a09a63b05aa2c56342a60ed4305b5f45938390b5
libs_dep=( libidn2 libxcrypt ncurses readline )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --with-idn
)

libs_build() {
    configure

    make SUIDMODE=

    for x in tftp tftpd syslogd traceroute; do
        cmdlet ./src/$x
    done

    cmdlet ./ping/ping
    cmdlet ./ping/ping6
    cmdlet ./telnet/telnet
    cmdlet ./telnetd/telnetd
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
