# Language server for the Go language

# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=0.23.0
libs_url=https://github.com/golang/tools/archive/refs/tags/gopls/v0.23.0.tar.gz
libs_sha=1ba41875b918db73c6a409ad8f552b85f72dfeea43ffb541b798322ff6b4152b

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
