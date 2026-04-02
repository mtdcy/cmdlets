# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.48.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.48.0.tar.gz
libs_sha=fa7f1bae65b22745a6c329f3c49b9876aa159b4e04d7803d78660809fc8af7d1
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
