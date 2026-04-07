#!/bin/bash
# Autoformat shell script source code

# shellcheck disable=SC2034
libs_name=shfmt
libs_lic="BSD-3-Clause"
libs_ver=3.13.1
libs_url=https://github.com/mvdan/sh/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=b31aad2d4c26b0c6e8ebe894d59022520bbebce33e082d7d29e4325eee35d308
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
