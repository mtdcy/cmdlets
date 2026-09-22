# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.5.8
libs_rev=1
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.5.8.tar.gz
libs_sha=9cce0a062dc257d36e7096c819e390b91de7bd1240b48a0c491d031f2cfeae46

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.verify -- "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
