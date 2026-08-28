#!/bin/bash
# Autoformat shell script source code

# shellcheck disable=SC2034
libs_name=shfmt
libs_lic="BSD-3-Clause"
libs_ver=3.14.0
libs_rev=1
libs_url=https://github.com/mvdan/sh/archive/refs/tags/v$libs_ver.tar.gz
libs_rev=1
libs_sha=f193c946e2882c4fa04935cd583f60e2cab60344209bd982a3a5933c4192aad8
libs_dep=()

# configure args
libs_args=()
libs_build() {
    go.clean

    go.build ./cmd/shfmt

    cmdlet shfmt

    check shfmt
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
