# Command-line packet analyzer

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=4.99.6
libs_url=https://www.tcpdump.org/release/tcpdump-4.99.6.tar.gz
libs_sha=5839921a0f67d7d8fa3dacd9cd41e44c89ccb867e8a6db216d62628c7fd14b09
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
