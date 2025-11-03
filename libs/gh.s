# GitHub’s official command line tool

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=2.82.1
libs_url=https://github.com/cli/cli/archive/refs/tags/v2.82.1.tar.gz
libs_sha=999bdea5c8baf3d03fe0314127c2c393d6c0f7a504a573ad0c107072973af973
libs_dep=( )

# configure args
libs_args=()
libs_build() {
    export GH_VERSION="$libs_ver"
    export GO_BUILDTAGS="updateable"

    go.setup

    make bin/gh

    cmdlet.install  bin/gh
    cmdlet.check    gh version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
