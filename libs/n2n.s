#!/bin/bash
# Peer-to-peer VPN

# shellcheck disable=SC2034
libs_name=n2n
libs_ver=3.1.1
libs_url=https://github.com/ntop/n2n/archive/refs/tags/$libs_ver.zip
libs_zip=n2n-$libs_ver.zip
libs_sha=3e3eb29ec3f6c8d79538776baea0eeb2d5f5f041b9c544091b7bee2a3afe44a8
libs_dep=()

libs_build() {
    export CFLAGS="$CFLAGS -Wno-incompatible-function-pointer-types"

    configure &&

    make &&

    cmdlet supernode &&

    cmdlet edge &&

    check supernode -h
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4

