# Clone of cat(1) with syntax highlighting and Git integration

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.26.1
libs_url=https://github.com/sharkdp/bat/archive/refs/tags/v0.26.1.tar.gz
libs_sha=4474de87e084953eefc1120cf905a79f72bbbf85091e30cf37c9214eafcaa9c9
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
