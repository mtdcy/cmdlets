# Command-line fuzzy finder written in Go

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=0.66.1
libs_url=https://github.com/junegunn/fzf/archive/refs/tags/v0.66.1.tar.gz
libs_sha=ae70923dba524d794451b806dbbb605684596c1b23e37cc5100daa04b984b706
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
