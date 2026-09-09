# Simple terminal UI for git commands

# shellcheck disable=SC2034
libs_name=lazygit
libs_lic="MIT"
libs_ver=0.65.0
libs_rev=1
libs_url=https://github.com/jesseduffield/lazygit/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=972151d83d8fdfa5c7c881c34349ba4a38c37b7085667696b85c443d2fca97ed

# configure args
libs_args=(
)

libs_build() {
    go version

    go clean

    go build .

    cmdlet.install lazygit
    cmdlet.verify -- lazygit
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
