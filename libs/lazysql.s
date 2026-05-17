# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.5.0
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.5.0.tar.gz
libs_sha=64234607848634342e1b98788f331f5908cfb27b93acaa5341d88e0a465cf464

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
