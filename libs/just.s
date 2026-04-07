# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.48.1
libs_url=https://github.com/casey/just/archive/refs/tags/1.48.1.tar.gz
libs_sha=290bb320b36ca118b8a8da6271660c941a8b0888b943de22e8238286e2312554
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
