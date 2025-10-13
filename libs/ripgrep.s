# Search tool like grep and The Silver Searcher

# shellcheck disable=SC2034
libs_name=ripgrep
libs_lic="Unlicensed"
libs_ver=14.1.1
libs_url=https://github.com/BurntSushi/ripgrep/archive/refs/tags/$libs_ver.tar.gz
libs_zip=$libs_name-$(basename "$libs_url")
libs_sha=4dad02a2f9c8c3c8d89434e47337aa654cb0e2aa50e806589132f186bf5c2b66
libs_dep=( pcre2 )

# configure args
libs_args=(
    --release
    --features pcre2
    --bin rg
    --verbose
)

libs_build() {
    cargo build &&

    cmdlet "$(find target -name rg)" &&

    check rg --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
