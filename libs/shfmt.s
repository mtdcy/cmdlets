#!/bin/bash
# Autoformat shell script source code

# shellcheck disable=SC2034
libs_name=shfmt
libs_lic="BSD-3-Clause"
libs_ver=3.11.0
libs_url=https://github.com/mvdan/sh/archive/refs/tags/v$libs_ver.tar.gz
libs_zip=$libs_name-$libs_ver.tar.gz
libs_sha=69aebb0dd4bf5e62842c186ad38b76f6ec2e781188cd71cea33cb4e729086e94
libs_dep=()

# configure args
libs_args=()
libs_build() {
    go clean || true

    go build ./cmd/shfmt &&

    cmdlet shfmt &&

    check shfmt
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
