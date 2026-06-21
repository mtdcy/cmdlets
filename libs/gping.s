# shellcheck disable=SC2034
libs_desc="Ping, but with a graph"

# rust-lld: warning: /data/cmdlets/out/x86_64-w64-mingw32/gping-1.20.1/target/release/build/libz-sys-9495903dea35b1c1/out/lib/libz.a: archive member 'f0389296f42960e9-compress.o' is neither ET_REL nor LLVM bitcode
libs_targets=( linux darwin )

libs_lic='MIT'
libs_ver=1.20.2
libs_url=https://github.com/orf/gping/archive/refs/tags/gping-v1.20.2.tar.gz
libs_sha=2aefe53acfa07c2a9316eee36bf3a99c9986d3351be854fd0cfe2f7dd0019154
libs_dep=( )

is_linux && libs_dep+=( iputils )

libs_args=(
    --release
    --verbose
)

libs_build() {
    cargo.setup

    cargo.build

    cmdlet.install "$(cargo.locate "$libs_name")"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
