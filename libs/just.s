# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.50.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.50.0.tar.gz
libs_sha=cca015e07739a1c26c6fc459f7d46e1e36ce0f7613114eddedd8cd3af55a10b7
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
