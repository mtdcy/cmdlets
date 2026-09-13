# Simple terminal UI for git commands

# shellcheck disable=SC2034
libs_name=lazygit
libs_lic="MIT"
libs_ver=0.65.1
libs_rev=1
libs_url=https://github.com/jesseduffield/lazygit/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=df30ec1a5032b3c5672a30090fe787fb32d4122fd996d6d85e1d10135acfbc89

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
