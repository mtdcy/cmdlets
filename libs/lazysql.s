# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.5.2
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.5.2.tar.gz
libs_sha=2e5baeda2d805a2efd8df65d9803087e8a3cb57f1cc205b2400f0d3240535040

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
