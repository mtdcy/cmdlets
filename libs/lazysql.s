# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.4.5
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.4.5.tar.gz
libs_sha=6c395c40c7400bfabbb5417feeed5fedbceb1058ba2971fe67c3a849f53d5a44

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
