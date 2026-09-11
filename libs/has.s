# Checks presence of various command-line tools and their versions on the path

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.6.0
libs_rev=1
libs_url=https://github.com/kdabir/has/archive/refs/tags/v1.6.0.tar.gz
libs_sha=99b4b82d8b935521bd1b44bf7a6af3421f4c850a28b8edfee39e6ee75af4d78f
libs_dep=( )

libs_args=(
)

libs_build() {
    cmdlet.install "$libs_name"

    cmdlet.verify -- "$libs_name" -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
