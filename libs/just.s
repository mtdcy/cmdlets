# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.57.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.57.0.tar.gz
libs_sha=905c556aad3c0a4b0376db98b706a9aa3485fcf50a30377d50737bf20f3792cb
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
