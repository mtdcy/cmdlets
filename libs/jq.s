# Lightweight and flexible command-line JSON processor

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.8.1
libs_url=https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-1.8.1.tar.gz
libs_sha=2be64e7129cecb11d5906290eba10af694fb9e3e7f9fc208a311dc33ca837eb0
libs_dep=( oniguruma )

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --disable-maintainer-mode

    --disable-docs

    --enable-all-static
    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make.all

    # fix pc file
    pkgconf libjq.pc -lm -lonig -lpthread -pthread

    pkgfile libjq -- make.install bin_PROGRAMS=

    cmdlet.install jq

    cmdlet.check jq --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
