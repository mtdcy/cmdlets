# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.53.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.53.0.tar.gz
libs_sha=9742f15ea4e6afd4bf9b8fecd0c5ef61904d3d187f24675601fdfbace885a4c3
libs_dep=( )

# configure args
libs_args=(
)

libs_build() {
    cargo.setup

    cargo.build

    cmdlet.install "$(cargo.locate $libs_name)"

    cmdlet.check "$libs_name"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
