# Simple terminal UI for git commands

# shellcheck disable=SC2034
libs_name=lazygit
libs_lic="MIT"
libs_ver=0.62.2
libs_url=https://github.com/jesseduffield/lazygit/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=0bd1cdbaf1a584d2eb2fd14f068a8eaaeaeb80d3e2713c72005de9e4feaf6844

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
