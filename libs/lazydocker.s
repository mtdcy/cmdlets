# Lazier way to manage everything docker

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.25.0
libs_url=https://github.com/jesseduffield/lazydocker/archive/refs/tags/v0.25.0.tar.gz
libs_sha=480234dec2dbe989462d177f1aa78debec972893ab5981d48d23d7aec8430a58

libs_args=(
)

libs_build() {
    go.setup

    go.build -tags release -o "$libs_name"

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
