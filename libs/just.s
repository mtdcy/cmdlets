# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.56.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.56.0.tar.gz
libs_sha=145cb76ccd858da30ee56de884dad9241b2706140bcf9ae189dfda5e5a62ed52
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
