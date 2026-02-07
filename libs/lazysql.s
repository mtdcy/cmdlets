# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.4.6
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.4.6.tar.gz
libs_sha=e8a06583d19f1053be13be800db5a3b6d273b992fcc335f539c40e39a6485e4c

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
