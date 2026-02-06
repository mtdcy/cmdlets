# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.45.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.45.0.tar.gz
libs_sha=e43dfa0f541fd8a115fb61de7c30d949d2f169d155fb1776abeaba9be7eb0e07
libs_dep=( )

# configure args
libs_args=(
)

libs_build() {
    cargo.setup

    cargo.build

    cmdlet.install "$(find target -name $libs_name)"

    cmdlet.check "$libs_name"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
