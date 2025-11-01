# Executing shell commands via HTTP server

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.17.0
libs_url=https://github.com/msoap/shell2http/archive/refs/tags/v1.17.0.tar.gz
libs_sha=17fab67e34e767accfbc59ab504971c704f54d79b57a023e6b5efa5556994624
libs_dep=( )

libs_args=(
)

libs_build() {
    go.setup

    go.build -tags release -o "$libs_name"

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
