# Simple, fast and user-friendly alternative to find

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=10.4.2
libs_url=https://github.com/sharkdp/fd/archive/refs/tags/v10.4.2.tar.gz
libs_sha=3a7e027af8c8e91c196ac259c703d78cd55c364706ddafbc66d02c326e57a456
libs_dep=( libpcap )

# configure args
libs_args=(
)

libs_build() {

    cargo.setup

    cargo.build

    cmdlet.install "$(cargo.locate $libs_name)"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
