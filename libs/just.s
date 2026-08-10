# Handy way to save and run project-specific commands

# shellcheck disable=SC2034
libs_ver=1.58.0
libs_url=https://github.com/casey/just/archive/refs/tags/1.58.0.tar.gz
libs_sha=c8a36e6e9397f2fdfcb0cc246fcdb790b52a784f3c8cabc0d8baeb031852a148
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
