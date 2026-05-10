# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.4.9
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.4.9.tar.gz
libs_sha=92a36347c064e2440f4f4bf38d3555ed282bb5ca7f0ebe3884d507cbcabaca9b

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
