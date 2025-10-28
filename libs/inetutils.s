# GNU utilities for networking

# shellcheck disable=SC2034
libs_lic='GPL-3.0+'
libs_ver=2.6
libs_url=(
    https://mirrors.ustc.edu.cn/gnu/inetutils/inetutils-2.6.tar.xz
    https://ftpmirror.gnu.org/gnu/inetutils/inetutils-2.6.tar.xz
)
libs_sha=68bedbfeaf73f7d86be2a7d99bcfbd4093d829f52770893919ae174c0b2357ca
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
