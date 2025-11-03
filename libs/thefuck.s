# Magnificent app which corrects your previous console command. 

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.8.1
libs_url=https://github.com/nvbn/thefuck/archive/refs/tags/3.32.tar.gz
libs_sha=
libs_dep=( )

libs_args=(
)

libs_build() {
    python.setup

    python.build fastentrypoints.py
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
