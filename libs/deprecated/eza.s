# A modern alternative to ls

# shellcheck disable=SC2034
libs_lic=EUPL-1.2
libs_ver=0.23.4
libs_url=https://github.com/eza-community/eza/archive/refs/tags/v0.23.4.tar.gz
libs_sha=9fbcad518b8a2095206ac385329ca62d216bf9fdc652dde2d082fcb37c309635
libs_dep=( libgit2 )

# configure args
libs_args=(
)

libs_build() {
    # use installed libgit2
    export LIBGIT2_NO_VENDOR=1

    cargo.setup

    cargo.build

    cmdlet.install "$(find target -name $libs_name)"

    cmdlet.check "$libs_name"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
