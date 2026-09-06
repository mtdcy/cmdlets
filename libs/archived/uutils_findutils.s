# Rust implementation of findutils: xargs find

# shellcheck disable=SC2034
libs_desc="Rust implementation of findutils"

libs_lic='MIT'
libs_ver=0.10.0
libs_url=https://github.com/uutils/findutils/archive/refs/tags/$libs_ver.tar.gz
libs_sha=e36ae3937f889bc59cfbd65820a642baa695c58d7fa1e387e41857e710f40419
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
