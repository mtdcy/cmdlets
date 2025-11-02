# Process YAML, JSON, XML, CSV and properties documents from the CLI

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=4.48.1
libs_url=https://github.com/mikefarah/yq/archive/refs/tags/v4.48.1.tar.gz
libs_sha=591158368f8155421bd8821754a67b4478ee2cde205b7abfbf2d50f90769cf0e

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install yq

    cmdlet.check yq --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
