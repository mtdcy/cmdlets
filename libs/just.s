# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.55.1
libs_url=https://github.com/casey/just/archive/refs/tags/1.55.1.tar.gz
libs_sha=40a2d3725480523ffebb762669cafe2b0135a00383946eec3d47adf5e9be6345
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
