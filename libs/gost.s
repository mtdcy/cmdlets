# GO Simple Tunnel - a simple tunnel written in golang

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=3.2.6
libs_url=https://github.com/go-gost/gost/archive/refs/tags/v3.2.6.tar.gz
libs_sha=79874354530b899576dd4866d3b1400651d0b17c1e7a90ad30c44686a0642600
libs_dep=()

# configure args
libs_args=()
libs_build() {
    go.build ./cmd/gost

    cmdlet.install  gost
    cmdlet.check    gost
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
