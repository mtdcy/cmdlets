# Effortlessly transfer files and folders, to and from your NFS server.

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.1.5
libs_url=https://github.com/kha7iq/ncp/archive/refs/tags/v0.1.5.tar.gz
libs_sha=ae4cb589ecc0bc13c1f18687058a085c7052e120ce58243d978ac79bf38a5b85

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
