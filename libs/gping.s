# shellcheck disable=SC2034
libs_desc="Ping, but with a graph"

libs_lic='MIT'
libs_ver=1.20.1
libs_url=https://github.com/orf/gping/archive/refs/tags/gping-v1.20.1.tar.gz
libs_sha=0df965111429d5fcef832a4ff23b452a1ec8f683d51ed31ce9b10902c0a18a9c
libs_dep=( )

is_linux && libs_dep+=( iputils )

libs_args=(
    --release
    --verbose
)

libs_build() {
    cargo build

    cmdlet "$(find target -name "$libs_name")"

    check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
