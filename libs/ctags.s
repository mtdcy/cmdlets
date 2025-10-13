# Maintained ctags implementation

# shellcheck disable=SC2034
libs_name=ctags
libs_lic="GPL-2.0-only"
libs_ver=6.2.0
libs_url=https://github.com/universal-ctags/ctags/releases/download/v$libs_ver/universal-ctags-$libs_ver.tar.gz
libs_sha=ae550fb8c5fdb5dfca2b1fc51a5de69300eddca9eb04bda9cc47b9703041763e
libs_dep=(pcre2 libyaml jansson libxml2 libiconv)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-included-regex
    --disable-external-sort
)

# macOS not support --enable-static.
is_darwin || libs_args+=(
    --disable-shared
    --enable-static
)

[[ "${libs_dep[*]}" =~ libiconv ]] || libs_args+=( --disable-iconv )

libs_build() {
    configure && make &&
    cmdlet ./ctags ctags etags &&
    check ctags
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
