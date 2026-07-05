# Ping Tool in Rust with Real-Time Data and Visualizations

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.7.1
libs_url=https://github.com/hanshuaikang/Nping/archive/refs/tags/v0.7.1.tar.gz
libs_sha=1a73f125601cac5ddc456b15d58b5145b859c46da24ce2024288fe4343050e5d
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
