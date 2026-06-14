# Rust implementation of findutils: xargs find

# shellcheck disable=SC2034
libs_desc="Rust implementation of findutils"

libs_lic='MIT'
libs_ver=0.9.0
libs_url=https://github.com/uutils/findutils/archive/refs/tags/$libs_ver.tar.gz
libs_sha=8b3eb813cac9fe519b77ee36705fdcd46b188d8807e98c0bb7126fabd8f64dda
libs_dep=()

libs_args=(
    --release
    --verbose
)

libs_build() {
    cargo.setup

    cargo.build

    cmdlet "$(cargo.locate find)"

    cmdlet "$(cargo.locate xargs)"

    check find --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
