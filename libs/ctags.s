# Maintained ctags implementation

# shellcheck disable=SC2034
libs_name=ctags
libs_lic="GPL-2.0-only"
libs_ver=6.2.1
libs_rev=2
libs_url=https://github.com/universal-ctags/ctags/releases/download/v$libs_ver/universal-ctags-$libs_ver.tar.gz
libs_sha=2c63efe9e0e083dc50e6fdd8c5414781cc8873d8c8940cf553c01870ed962f8c
libs_dep=(pcre2 libyaml jansson libxml2 libiconv)

libs_args=(
    --with-included-regex
    --disable-external-sort
)

# macOS not support --enable-static.
# linux-gnu + zig cc will fail with --enable-static
is_musl && libs_args+=(
    --enable-static --disable-shared
)

[[ "${libs_dep[*]}" =~ libiconv ]] || libs_args+=(--disable-iconv)

libs_build() {
    configure

    make

    cmdlet.install ./ctags ctags etags

    cmdlet.verify ctags
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
