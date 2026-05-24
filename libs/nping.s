# Ping Tool in Rust with Real-Time Data and Visualizations

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.7.0
libs_url=https://github.com/hanshuaikang/Nping/archive/refs/tags/v0.7.0.tar.gz
libs_sha=344d49df5a117be5b52662113c84581f8b8c245b3f50cae40bbb944a4fce89c0
libs_dep=( )

libs_args=(
    --release
    --verbose
)

libs_build() {

    cargo build

    if version.ge 0.6.1; then
        cmdlet "$(find target -name nbping)" nbping nping
    else
        cmdlet "$(find target -name "$libs_name")"
    fi

    check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
