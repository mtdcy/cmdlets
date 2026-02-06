# Ping Tool in Rust with Real-Time Data and Visualizations

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.6.0
libs_url=https://github.com/hanshuaikang/Nping/archive/refs/tags/v0.6.0.tar.gz
libs_sha=07ca7ce514b9e9584c33fc6e75c4b4974845deb348833cf92814a34ef4cbaca3
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
