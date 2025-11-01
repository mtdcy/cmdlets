# Disk Usage/Free Utility - a better 'df' alternative

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.9.1
libs_url=https://github.com/muesli/duf/archive/refs/tags/v0.9.1.tar.gz
libs_sha=1334d8c1a7957d0aceebe651e3af9e1c1e0c6f298f1feb39643dd0bd8ad1e955

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
