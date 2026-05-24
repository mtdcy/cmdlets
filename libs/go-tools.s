# Language server for the Go language

# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=0.22.0
libs_url=https://github.com/golang/tools/archive/refs/tags/gopls/v0.22.0.tar.gz
libs_sha=249dc0c4b9f3e853f6a7fb6f3528db2f48793e7c54323f3b32aa38f6432f088a

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
