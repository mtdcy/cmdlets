# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.55.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.55.0.tar.gz
libs_sha=5e71c72193f027a60dc8fc1399d4d7cbc5763770d17370835a5e02cca554d80f
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
