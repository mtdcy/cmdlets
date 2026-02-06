# Power of curl, ease of use of httpie

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.8.2
libs_url=https://github.com/rs/curlie/archive/refs/tags/v1.8.2.tar.gz
libs_sha=846ca3c5f2cca60c15eaef24949cf49607f09bdd68cbe9d81a2a026e434fa715
libs_dep=( curl )

libs_args=(
)

libs_build() {
    go.setup

    go.build -tags release -o "$libs_name"

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
