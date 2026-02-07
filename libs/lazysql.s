# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.4.7
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.4.7.tar.gz
libs_sha=7d0ebba0e9549b3f43d25358a6633e706ab3b1a410d323add7c7ef3397071f37

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
