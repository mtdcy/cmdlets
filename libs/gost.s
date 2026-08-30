# GO Simple Tunnel - a simple tunnel written in golang

# shellcheck disable=SC2034
libs_lic='MIT'
libs_rev=1
libs_ver=3.3.0
libs_url=https://github.com/go-gost/gost/archive/refs/tags/v3.3.0.tar.gz
libs_sha=2a65e2da14fef6b6da8d4e32a8bc62e39970dbb141db42bc6f5821f90ac1e9a3
libs_dep=()

# configure args
libs_args=()
libs_build() {
    go.build ./cmd/gost

    cmdlet.install  gost
    cmdlet.check    gost
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
