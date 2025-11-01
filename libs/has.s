# Checks presence of various command-line tools and their versions on the path

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.5.2
libs_url=https://github.com/kdabir/has/archive/refs/tags/v1.5.2.tar.gz
libs_sha=965629d00b9c41fab2a9c37b551e3d860df986d86cdebd9b845178db8f1c998e
libs_dep=( )

libs_args=(
)

libs_build() {
    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
