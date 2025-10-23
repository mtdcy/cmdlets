# GNU grep, egrep and fgrep
#
# shellcheck disable=SC2034

libs_lic='GPL-3.0-or-later'
libs_ver=3.12
libs_url=https://ftpmirror.gnu.org/gnu/grep/grep-$libs_ver.tar.xz
libs_sha=2649b27c0e90e632eadcd757be06c6e9a4f48d941de51e7c0f83ff76408a07b9
libs_dep=(libiconv pcre2)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-perl-regexp # pcre2

    --without-selinux
    --disable-rpath

    # no i18n or nls
    --disable-nls
    --without-libintl-prefix

    --disable-doc
    --disable-man
)

[[ ${libs_dep[*]} =~ libiconv ]] || libs_args+=(--without-libiconv-prefix)

libs_build() {
    # note: egrep & fgrep are obsolescent;
    configure

    make -C lib
    make -C src grep

    # check: grep with pcre
    echo FOO | ./src/grep -P '(?i)foo' || die "check grep with pcre failed"

    # install grep
    cmdlet ./src/grep

    # verify
    check grep
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
