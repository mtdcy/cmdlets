# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.47.1
libs_url=https://github.com/casey/just/archive/refs/tags/1.47.1.tar.gz
libs_sha=2976e02f2dffd1ddc9cba57ef2fe75e8f4b97fde1657ee6fd145ab01efd789a7
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
