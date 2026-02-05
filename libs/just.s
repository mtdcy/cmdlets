# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.44.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.44.0.tar.gz
libs_sha=450ab569b76053ec34c2ae0616cdf50114a4dce0c2e8dfba2d79bdfb60081a04
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
