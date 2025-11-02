# Simple, fast and user-friendly alternative to find

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=10.3.0
libs_url=https://github.com/sharkdp/fd/archive/refs/tags/v10.3.0.tar.gz
libs_sha=2edbc917a533053855d5b635dff368d65756ce6f82ddefd57b6c202622d791e9
libs_dep=( libpcap )

# configure args
libs_args=(
)

libs_build() {

    cargo.setup

    cargo.build

    cmdlet.install "$(find target -name $libs_name)"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
