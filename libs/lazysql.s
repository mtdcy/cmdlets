# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.5.5
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.5.5.tar.gz
libs_sha=e979b86b7b40e03987d5855cece649791cf6307fc5785e1c6aac96ce6ee5135a

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
