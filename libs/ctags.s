# Maintained ctags implementation

# shellcheck disable=SC2034
upkg_name=ctags
upkg_lic="GPL-2.0-only"
upkg_ver=6.2.0
upkg_url=https://github.com/universal-ctags/ctags/releases/download/v$upkg_ver/universal-ctags-$upkg_ver.tar.gz
upkg_sha=ae550fb8c5fdb5dfca2b1fc51a5de69300eddca9eb04bda9cc47b9703041763e
upkg_dep=(pcre2 libyaml jansson libxml2 libiconv)

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-included-regex
    --disable-external-sort
)

# macOS not support --enable-static.
is_darwin || upkg_args+=(
    --disable-shared
    --enable-static
)

[[ "${upkg_dep[*]}" =~ libiconv ]] || upkg_args+=( --disable-iconv )

upkg_static() {
    configure && make &&
    cmdlet ./ctags ctags etags &&
    check ctags
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
