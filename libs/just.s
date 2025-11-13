# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.43.1
libs_url=https://github.com/casey/just/archive/refs/tags/1.43.1.tar.gz
libs_sha=741b5c6743501dc4dbd23050dd798f571d873d042b67bcea113d622b0c37d180
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
