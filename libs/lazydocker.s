# Lazier way to manage everything docker

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.24.1
libs_url=https://github.com/jesseduffield/lazydocker/archive/refs/tags/v0.24.1.tar.gz
libs_sha=f54197d333a28e658d2eb4d9b22461ae73721ec9e4106ba23ed177fc530c21f4

libs_args=(
)

libs_build() {
    go.setup

    go.build -tags release -o "$libs_name"

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
