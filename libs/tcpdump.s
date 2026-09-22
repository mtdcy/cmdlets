# Command-line packet analyzer

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=4.99.7
libs_rev=1
libs_url=https://www.tcpdump.org/release/tcpdump-4.99.7.tar.gz
libs_sha=8be364e28d3b745ef1459b385cd2f4bc0e1ebad7a5d2ebdf70071d6c9b5b9a54
libs_dep=(libpcap openssl)

libs_args=(
    --disable-smb
    --disable-universal
    --disable-local-libpcap
)

libs_build() {
    configure

    make

    cmdlet.install ./tcpdump

    cmdlet.verify -- tcpdump --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
