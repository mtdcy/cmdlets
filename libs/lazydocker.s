# Lazier way to manage everything docker

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.24.4
libs_url=https://github.com/jesseduffield/lazydocker/archive/refs/tags/v0.24.4.tar.gz
libs_sha=f8299de3c1a86b81ff70e2ae46859fc83f2b69e324ec5a16dd599e8c49fb4451

libs_args=(
)

libs_build() {
    go.setup

    go.build -tags release -o "$libs_name"

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
