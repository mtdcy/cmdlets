# Ping Tool in Rust with Real-Time Data and Visualizations

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.6.1
libs_url=https://github.com/hanshuaikang/Nping/archive/refs/tags/v0.6.1.tar.gz
libs_sha=48d46e11cec3c69e6c28e91fefbba47f4773aab1c9d8c1f15e276311f79c43ec
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
