# Simple, fast and user-friendly alternative to find

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=10.5.0
libs_rev=1
libs_url=https://github.com/sharkdp/fd/archive/refs/tags/v10.5.0.tar.gz
libs_sha=e6d9e90730bf316101691e49d59cc02565278dc3779d33a77423801569484851
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
