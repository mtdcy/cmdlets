# GNU grep, egrep and fgrep
#
# shellcheck disable=SC2034

upkg_lic='GPL-3.0-or-later'
upkg_ver=3.12
upkg_url=https://ftpmirror.gnu.org/gnu/grep/grep-$upkg_ver.tar.xz
upkg_sha=2649b27c0e90e632eadcd757be06c6e9a4f48d941de51e7c0f83ff76408a07b9
upkg_dep=(libiconv pcre2)

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-perl-regexp

    --without-selinux
    --disable-nls
    --disable-rpath

    --disable-doc
    --disable-man
)

[[ ${upkg_dep[*]} =~ libiconv ]] || upkg_args+=(--without-libiconv-prefix)

upkg_static() {
    # note: egrep & fgrep are obsolescent;
    configure && 
    make -C lib &&
    make -C src grep &&

    # install grep
    cmdlet ./src/grep &&
    # verify
    check grep &&
    # check: grep with pcre
    echo FOO | grep -P '(?i)foo'
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
