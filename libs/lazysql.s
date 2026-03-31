# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.4.8
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.4.8.tar.gz
libs_sha=bc6f00759376a30cbeb28af3200a0df2ab3df07f41717be2cf08122827e1671f

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
