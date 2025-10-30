# Ping Tool in Rust with Real-Time Data and Visualizations

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.5.0
libs_url=https://github.com/hanshuaikang/Nping/archive/refs/tags/v0.5.0.tar.gz
libs_sha=0ba70f55fc126445b8c57be234c2eb355939336c731c8209b320bd89b85cac50
libs_dep=( )

libs_args=(
    --release
    --verbose
)

libs_build() {

    cargo build

    cmdlet "$(find target -name $libs_name)" "$libs_name"

    check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
