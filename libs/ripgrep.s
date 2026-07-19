# Search tool like grep and The Silver Searcher

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=15.2.0
libs_url=https://github.com/BurntSushi/ripgrep/archive/refs/tags/$libs_ver.tar.gz
libs_sha=7605249d3eb0d5f170e3414498e3344e26b1e7a147aec518b57090b80036a562
libs_dep=( pcre2 )

is_musl && libs_dep+=( jemalloc )

# configure args
libs_args=(
    --release
    --features pcre2
    --bin rg
    --verbose
    #--profile release-lto
)

libs_build() {
    export PCRE2_SYS_STATIC=1

    # https://bugs.gentoo.org/show_bug.cgi?format=multiple&id=927338
    if is_musl; then
        export CARGO_FEATURE_UNPREFIXED_MALLOC_ON_SUPPORTED_PLATFORMS=1
        export JEMALLOC_OVERRIDE="$PREFIX/lib/libjemalloc.a"
    fi

    cargo.setup

    cargo.build

    cmdlet.install "$(cargo.locate rg)"

    cmdlet.check rg --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
