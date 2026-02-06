# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.4.4
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.4.4.tar.gz
libs_sha=04929c9422a2c427f442ce7210804a2a48c82eaaf0870130009763c58f797270

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
