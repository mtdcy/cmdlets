# Command-line fuzzy finder written in Go

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=0.68.0
libs_url=https://github.com/junegunn/fzf/archive/refs/tags/v0.68.0.tar.gz
libs_sha=ed878dcb57e083129db5d8a28c656fd981ce90f12b67d32024888d33790ca3a6
libs_dep=( ncurses )

# configure args
libs_args=()
libs_build() {
    go.setup

    go.build

    cmdlet.install  "$libs_name"
    cmdlet.check    "$libs_name"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
