# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.5.3
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.5.3.tar.gz
libs_sha=be1ec5b79f42e26536189fbd7116e95288ea4b15bf356e14c548e14dd45a3e33

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
