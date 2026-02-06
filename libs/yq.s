# Process YAML, JSON, XML, CSV and properties documents from the CLI

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=4.48.2
libs_url=https://github.com/mikefarah/yq/archive/refs/tags/v4.48.2.tar.gz
libs_sha=af464e5c227ad3894628de65db2996db0e4716a16388eaf08bfa73e93ad0604e

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install yq

    cmdlet.check yq --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
