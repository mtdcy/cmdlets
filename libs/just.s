# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.47.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.47.0.tar.gz
libs_sha=6b5d6f172c8f1c7babd0d76047143741b54b54d62e2abf4061863b24931461d5
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
