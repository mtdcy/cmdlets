# Rust implementation of findutils: xargs find

# shellcheck disable=SC2034
libs_desc="Rust implementation of findutils"

libs_lic='MIT'
libs_ver=0.9.1
libs_url=https://github.com/uutils/findutils/archive/refs/tags/$libs_ver.tar.gz
libs_sha=ac60fa34c09110a386c3782e94f5ca3f9294f64edf82855637c630c36de65ed3
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
