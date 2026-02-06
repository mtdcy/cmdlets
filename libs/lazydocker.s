# Lazier way to manage everything docker

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.24.2
libs_url=https://github.com/jesseduffield/lazydocker/archive/refs/tags/v0.24.2.tar.gz
libs_sha=2a8421f7c72b0a08b50f95af0994cef8c21cc16173fef23011849e50831ae33c

libs_args=(
)

libs_build() {
    go.setup

    go.build -tags release -o "$libs_name"

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
