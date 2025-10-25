# Language server for the Go language

# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=0.20.0
libs_url=https://github.com/golang/tools/archive/refs/tags/gopls/v0.20.0.tar.gz
libs_sha=1ff2a83be8be5a61b97fc5d72eab66f368ec20b52c513cc6656fc2e502e46f19

# configure args
libs_args=(
)

libs_build() {
    pushd gopls || die

    go build && cmdlet ./gopls

    popd || die

    pushd cmd/goimports || die

    go build && cmdlet ./goimports

    popd || die

    check gopls version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
