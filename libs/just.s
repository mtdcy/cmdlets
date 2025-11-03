# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.43.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.43.0.tar.gz
libs_sha=03904d6380344dbe10e25f04cd1677b441b439940257d3cc9d8c5f09d91e3065
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
