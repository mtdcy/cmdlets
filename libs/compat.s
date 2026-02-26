# system compat layer

# shellcheck disable=SC2034
libs_lic=BSD
libs_ver=1.0

libs_deps=( libintl )

is_musl && libs_deps+=(
    libargp
    musl-obstack
    musl-fts
)

is_mingw && libs_deps+=( cppwinrt )

libs_build() {
    true
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
