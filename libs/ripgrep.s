# Search tool like grep and The Silver Searcher

# shellcheck disable=SC2034
upkg_name=ripgrep
upkg_lic="Unlicensed"
upkg_ver=14.1.1
upkg_url=https://github.com/BurntSushi/ripgrep/archive/refs/tags/$upkg_ver.tar.gz
upkg_zip=$upkg_name-$(basename "$upkg_url")
upkg_sha=4dad02a2f9c8c3c8d89434e47337aa654cb0e2aa50e806589132f186bf5c2b66
upkg_dep=( pcre2 )

# configure args
upkg_args=(
    --release
    --features pcre2
    --bin rg
    --verbose
)

upkg_static() {
    cargo build &&

    cmdlet "$(find target -name rg)" &&

    check rg --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
