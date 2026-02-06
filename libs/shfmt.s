#!/bin/bash
# Autoformat shell script source code

# shellcheck disable=SC2034
libs_name=shfmt
libs_lic="BSD-3-Clause"
libs_ver=3.12.0
libs_url=https://github.com/mvdan/sh/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=ac15f42feeba55af29bd07698a881deebed1cd07e937effe140d9300e79d5ceb
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
