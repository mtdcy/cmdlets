# Search tool like grep and The Silver Searcher

# shellcheck disable=SC2034
libs_name=ripgrep
libs_lic="Unlicensed"
libs_ver=15.1.0
libs_url=https://github.com/BurntSushi/ripgrep/archive/refs/tags/$libs_ver.tar.gz
libs_sha=046fa01a216793b8bd2750f9d68d4ad43986eb9c0d6122600f993906012972e8
libs_dep=( pcre2 )

is_musl && libs_dep+=( jemalloc )

# configure args
libs_args=(
    --release
    --features pcre2
    --bin rg
    --verbose
)

libs_build() {
    # https://bugs.gentoo.org/show_bug.cgi?format=multiple&id=927338
    if is_musl; then
        export CARGO_FEATURE_UNPREFIXED_MALLOC_ON_SUPPORTED_PLATFORMS=1
        export JEMALLOC_OVERRIDE="$PREFIX/lib/libjemalloc.a"
    fi

    cargo.setup

    cargo.build

    cmdlet.install "$(find target -name rg)"

    cmdlet.check rg --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
