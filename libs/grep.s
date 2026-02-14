# GNU grep, egrep and fgrep
#
# shellcheck disable=SC2034

libs_lic='GPL-3.0-or-later'
libs_ver=3.12
libs_url=https://ftpmirror.gnu.org/gnu/grep/grep-$libs_ver.tar.xz
libs_sha=2649b27c0e90e632eadcd757be06c6e9a4f48d941de51e7c0f83ff76408a07b9
libs_deps=(libiconv pcre2)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # no i18n or nls
    --disable-nls
    --without-libintl-prefix

    # disabled features
    --without-selinux
    --disable-doc
    --disable-man
)

is_listed libiconv  "${libs_deps[@]}" && libs_args+=( --with-libiconv      ) || libs_args+=( --without-libiconv-prefix )
is_listed pcre2     "${libs_deps[@]}" && libs_args+=( --enable-perl-regexp ) || libs_args+=( --disable-perl-regexp     )

libs_build() {
    # note: egrep & fgrep are obsolescent;
    configure

    make

    # check: grep with pcre
    echo FOO | run src/grep -P '(?i)foo' || die "check grep with pcre failed"

    # install grep
    cmdlet.install src/grep

    # verify
    cmdlet.check grep --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
