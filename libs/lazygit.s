# Simple terminal UI for git commands

# shellcheck disable=SC2034
libs_name=lazygit
libs_lic="MIT"
libs_ver=0.56.0
libs_url=https://github.com/jesseduffield/lazygit/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=8785a17f52549640d1bacab66bec3156b9208c46390bb597002eeb3734085a00

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
