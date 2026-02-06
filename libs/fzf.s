# Command-line fuzzy finder written in Go

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=0.67.0
libs_url=https://github.com/junegunn/fzf/archive/refs/tags/v0.67.0.tar.gz
libs_sha=da72936dd23045346769dbf233a7a1fa6b4cfe4f0e856b279821598ce8f692af
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
