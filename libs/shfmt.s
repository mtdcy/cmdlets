#!/bin/bash
# Autoformat shell script source code

# shellcheck disable=SC2034
libs_name=shfmt
libs_lic="BSD-3-Clause"
libs_ver=3.14.1
libs_rev=1
libs_url=https://github.com/mvdan/sh/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=ec4bdb88ab6c95686be3a4eeb4ad77d2b49d33d2ed7b0a65035cd52d2d87c443
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
