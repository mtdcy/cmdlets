# Language server for the Go language

# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=0.21.0
libs_url=https://github.com/golang/tools/archive/refs/tags/gopls/v0.21.0.tar.gz
libs_sha=c223293463c98039a930cb604d6ff04caff5cd6a3d45e7394cda1f11d8cfc0b5

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
