# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.44.1
libs_url=https://github.com/casey/just/archive/refs/tags/1.44.1.tar.gz
libs_sha=ad93602b25c87de0f3cb90c5970a5b8f5ccca6fb87ae393be7e85477d6bbd268
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
