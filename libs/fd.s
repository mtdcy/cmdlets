# Simple, fast and user-friendly alternative to find

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=10.4.1
libs_url=https://github.com/sharkdp/fd/archive/refs/tags/v10.4.1.tar.gz
libs_sha=59ab83e56743e28eaa92c5497b3998a35744db6d8d574f389456481f2af1cb00
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
