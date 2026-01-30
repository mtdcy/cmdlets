# Drop-in replacement of diffutils in Rust

# shellcheck disable=SC2034
libs_desc="Drop-in replacement of diffutils in Rust"

libs_lic='MIT'
libs_ver=0.5.0
libs_url=https://github.com/uutils/diffutils/archive/refs/tags/v0.5.0.tar.gz
libs_sha=4c05d236ebddef7738446980a59cd13521b6990ea02242db6b32321dd93853ca
libs_dep=()

libs_args=(
)

libs_build() {
    cargo.build

    cmdlet.install "$(find target -name diffutils)" diffutils cmp diff

    cmdlet.check diffutils
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
