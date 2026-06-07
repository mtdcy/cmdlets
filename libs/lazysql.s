# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.5.1
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.5.1.tar.gz
libs_sha=0b5b7f35c8dd7da584831a389e22f7bd9809cc7f245ddd970758b4d7524eb5fc

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
