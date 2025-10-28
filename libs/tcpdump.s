# Command-line packet analyzer

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=4.99.5
libs_url=https://www.tcpdump.org/release/tcpdump-4.99.5.tar.gz
libs_sha=8c75856e00addeeadf70dad67c9ff3dd368536b2b8563abf6854d7c764cd3adb
libs_dep=( libpcap openssl )

libs_args=(
    --disable-smb
    --disable-universal
    --disable-local-libpcap
)

libs_build() {
    configure

    make

    cmdlet ./tcpdump

    check tcpdump --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
