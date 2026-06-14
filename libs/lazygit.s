# Simple terminal UI for git commands

# shellcheck disable=SC2034
libs_name=lazygit
libs_lic="MIT"
libs_ver=0.62.1
libs_url=https://github.com/jesseduffield/lazygit/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=198602c75c0d971b56088d6d364aaf9b2fd52bcadcb0e6a8548df0ed43e4dac2

# configure args
libs_args=(
)

libs_build() {
    go version || true

    go clean || true

    go build . &&

    cmdlet lazygit &&

    check lazygit
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
