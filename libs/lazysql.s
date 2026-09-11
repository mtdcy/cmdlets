# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.5.7
libs_rev=1
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.5.7.tar.gz
libs_sha=90d6943d0208964aa6143da9d0768fa0dfc2bfd7a4ca2302ba7b36ec92808334

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.verify -- "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
