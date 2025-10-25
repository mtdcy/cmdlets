# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
# shellcheck disable=SC2034
libs_desc="Secure hashing function"
libs_lic='CC0-1.0'
libs_ver=0.98.1
libs_url=(
    https://github.com/BLAKE2/libb2/releases/download/v$libs_ver/libb2-$libs_ver.tar.gz
)
libs_sha=53626fddce753c454a3fea581cbbc7fe9bbcf0bc70416d48fdbbf5d87ef6c72e
libs_dep=( )

# Fix -flat_namespace being used on Big Sur and later.
libs_patches=(
    https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff
)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # static only
    --disable-shared
    --enable-static
)

# SSE detection is broken on arm64 macos
# https://github.com/BLAKE2/libb2/issues/36
is_arm64 || libs_args+=( --enable-fat )

libs_build() {
    configure

    make

    pkgfile libb2 -- make install
}
