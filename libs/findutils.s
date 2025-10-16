# Rust implementation of findutils: xargs find

# shellcheck disable=SC2034
libs_desc="Rust implementation of findutils"

libs_lic='MIT'
libs_ver=0.8.3
libs_url=https://github.com/uutils/findutils/archive/refs/tags/0.8.0.tar.gz
libs_sha=932f153d256f7a4cf40255a948689bf59a10f14c8804151817ab50fa1b46429a
libs_dep=()

libs_args=(
    --release
    --verbose
)

libs_build() {
    cargo build &&
    
    cmdlet "$(find target -name find)" &&
    
    cmdlet "$(find target -name xargs)" &&

    check find --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
