# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.5.9
libs_rev=1
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.5.9.tar.gz
libs_sha=f7d6bd4dfc9f7b72d2fbae076dc8d8c05773a970978a4e9ac3458dfb393c3f33

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.verify -- "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
