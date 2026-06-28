# Cross-platform TUI database management tool

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.5.4
libs_url=https://github.com/jorgerojas26/lazysql/archive/refs/tags/v0.5.4.tar.gz
libs_sha=f2ee82ca2bb4063eae8cb12c63cedaba39b1665dbe65492695105f4262c1c865

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
