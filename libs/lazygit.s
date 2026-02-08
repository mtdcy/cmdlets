# Simple terminal UI for git commands

# shellcheck disable=SC2034
libs_name=lazygit
libs_lic="MIT"
libs_ver=0.53.0
libs_url=https://github.com/jesseduffield/lazygit/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=c160053ae99cb741c6d4295d52f917e492168b204780f9ad1afe8f984c6604a6

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
