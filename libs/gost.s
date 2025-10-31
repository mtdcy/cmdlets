# GO Simple Tunnel - a simple tunnel written in golang

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=3.2.5
libs_url=https://github.com/go-gost/gost/archive/refs/tags/v3.2.5.tar.gz
libs_sha=fb9840530ded8067622f3c91365300f02b1feccdb7a873e6397eb12d6ed6e01f
libs_dep=()

# configure args
libs_args=()
libs_build() {
    go.build ./cmd/gost

    cmdlet.install  gost
    cmdlet.check    gost
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
