# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.5.6
libs_rev=1
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.5.6.tar.gz
libs_sha=ec2cd213f36b4fee1e73f8da528a8e19344d1013d4a1af5005f66bc44f0b93fc

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
