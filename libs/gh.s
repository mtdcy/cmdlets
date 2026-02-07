# GitHub’s official command line tool

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=2.83.1
libs_url=https://github.com/cli/cli/archive/refs/tags/v2.83.1.tar.gz
libs_sha=5053825b631fa240bba1bfdb3de6ac2c7af5e3c7884b755a6a5764994d02f999
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
