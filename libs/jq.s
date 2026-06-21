# Lightweight and flexible command-line JSON processor

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.8.2
libs_url=https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-1.8.2.tar.gz
libs_sha=71b8d6e8f5fe81f6c6d0d110e3892251f6ce76ed095abd315e26e6e1193af3af
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
