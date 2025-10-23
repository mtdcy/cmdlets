# Pager program similar to more

# shellcheck disable=SC2034
libs_lic="GPL-3.0-or-later"
libs_ver=679
libs_url=https://www.greenwoodsoftware.com/less/less-679.tar.gz
libs_sha=9b68820c34fa8a0af6b0e01b74f0298bcdd40a0489c61649b47058908a153d78
libs_dep=( ncurses pcre2 )

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --disable-nls

    --with-regex=pcre2

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make less

    cmdlet ./less

    check less --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
