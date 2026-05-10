# Simple terminal UI for git commands

# shellcheck disable=SC2034
libs_name=lazygit
libs_lic="MIT"
libs_ver=0.61.0
libs_url=https://github.com/jesseduffield/lazygit/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=24b0ce4f98834f2b2df0a015a13d6846d2711eba8ae2c0e5612c84dbc55b4c10

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
