# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.46.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.46.0.tar.gz
libs_sha=f60a578502d0b29eaa2a72c5b0d91390b2064dfd8d1a1291c3b2525d587fd395
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
