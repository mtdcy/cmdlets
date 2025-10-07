# Rust implementation of findutils: xargs find

# shellcheck disable=SC2034
upkg_desc="Rust implementation of findutils"

upkg_lic='MIT'
upkg_ver=0.8.0
upkg_url=https://github.com/uutils/findutils/archive/refs/tags/0.8.0.tar.gz
upkg_sha=932f153d256f7a4cf40255a948689bf59a10f14c8804151817ab50fa1b46429a
upkg_dep=()

upkg_args=(
    --release
    --verbose
)

upkg_static() {
    cargo build &&
    
    cmdlet "$(find target -name find)" &&
    
    cmdlet "$(find target -name xargs)" &&

    check find --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
