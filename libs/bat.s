# Clone of cat(1) with syntax highlighting and Git integration

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.26.0
libs_url=https://github.com/sharkdp/bat/archive/refs/tags/v0.26.0.tar.gz
libs_sha=ccf3e2b9374792f88797a28ce82451faeae0136037cb8c8b56ba0a6c1a94fd69
libs_dep=( libgit2 oniguruma )

# configure args
libs_args=(
)

libs_build() {
    # use installed libgit2
    export LIBGIT2_NO_VENDOR=1
    # use installed static onig
    export RUSTONIG_SYSTEM_LIBONIG=1
    export RUSTONIG_DYNAMIC_LIBONIG=0

    cargo.setup

    cargo.build

    cmdlet.install "$(find target -name $libs_name)"

    cmdlet.check "$libs_name"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
