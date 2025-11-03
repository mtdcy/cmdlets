# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.4.3
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.4.3.tar.gz
libs_sha=7d4a1b2f819c8c78c72a885e1c4642c3d1d520bcddbf6bee63a311e798a0d77b

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
