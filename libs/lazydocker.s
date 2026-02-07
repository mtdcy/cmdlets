# Lazier way to manage everything docker

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.24.3
libs_url=https://github.com/jesseduffield/lazydocker/archive/refs/tags/v0.24.3.tar.gz
libs_sha=d6676b678105517a183d878180b041f186cd45a5591a2a7f25f30d5c0ee17670

libs_args=(
)

libs_build() {
    go.setup

    go.build -tags release -o "$libs_name"

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
