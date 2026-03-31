# Language server for the Go language

# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=0.21.1
libs_url=https://github.com/golang/tools/archive/refs/tags/gopls/v0.21.1.tar.gz
libs_sha=af211e00c3ffe44fdf2dd3efd557e580791e09f8dbb4284c917bd120bc3c8f9c

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
