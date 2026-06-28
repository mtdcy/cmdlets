# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.54.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.54.0.tar.gz
libs_sha=53d288296054876d4d9fb76b0f947c3f2a805969bfa19ec79108da44e70cd93e
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
