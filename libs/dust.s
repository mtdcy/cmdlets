# More intuitive version of du in rust

# shellcheck disable=SC2034
libs_lic=Apache-2.0
libs_ver=1.2.3
libs_url=https://github.com/bootandy/dust/archive/refs/tags/v1.2.3.tar.gz
libs_sha=424b26adfbafeac31da269ecb3f189eca09803e60fad90b3ff692cf52e0aeeee
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
