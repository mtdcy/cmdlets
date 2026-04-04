# Simple, fast and user-friendly alternative to find

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=10.4.0
libs_url=https://github.com/sharkdp/fd/archive/refs/tags/v10.4.0.tar.gz
libs_sha=9caf8509134fe304ce5ee4667804216d93fe61df11ff941f48a240d40495db16
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
