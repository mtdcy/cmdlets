# More intuitive version of du in rust

# shellcheck disable=SC2034
libs_lic=Apache-2.0
libs_ver=1.2.5
libs_rev=1
libs_url=https://github.com/bootandy/dust/archive/refs/tags/v1.2.5.tar.gz
libs_sha=4445e61f1341ea567e9e49367f275a1f4b026a60526e60048265f7af4a4943fd
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
