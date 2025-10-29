# Implementation of the STUN protocol

# shellcheck disable=SC2034
libs_lic='Apache-2.0'
libs_ver=1.2.16
libs_url=https://www.stunprotocol.org/stunserver-1.2.16.tgz
libs_sha=4479e1ae070651dfc4836a998267c7ac2fba4f011abcfdca3b8ccd7736d4fd26
libs_dep=( boost )

# on macOS, stuntman uses CommonCrypt
is_darwin || libs_dep+=( openssl )

libs_args=(
)

libs_build() {
    make

    cmdlet ./server/stunserver
    cmdlet ./client/stunclient

    check stunclient

    caveats << EOF
static built stun client and server @ $libs_ver

Example:
    stuclient --mode behavior stun.miwifi.com
EOF
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
