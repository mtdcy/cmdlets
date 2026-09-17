# More intuitive version of du in rust

# shellcheck disable=SC2034
libs_targets=(linux darwin)

libs_lic=Apache-2.0
libs_ver=1.2.6
libs_rev=1
libs_url=https://github.com/bootandy/dust/archive/refs/tags/v1.2.6.tar.gz
libs_sha=9dd1ec7576d43574e6f48342cb96a5087338b4c308460a848f5895f72ddc3bc9

libs_deps=(libpcap)

# configure args
libs_args=(
)

libs_build() {

    cargo.setup

    cargo.build

    cmdlet.install "$(cargo.locate $libs_name)"

    cmdlet.verify -- "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
