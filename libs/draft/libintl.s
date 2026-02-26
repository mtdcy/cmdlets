# stub libintl.h
#
# XXX: we do not need internationalization (i18n) and localization (l10n), but some program has no option disable it.
#  => create a stub libintl.h

# shellcheck disable=SC2034
libs_lic=BSD
libs_ver=1.0
libs_url=
libs_sha=

<<<<<<<< HEAD:libs/draft/libintl.s
libs_deps=( libunistring libxml2 ncurses libiconv )
|||||||| parent of 1231869 (stub libintl.h):libs/libintl.s
libs_deps=( libunistring libxml2 ncurses )
========
libs_deps=( )
>>>>>>>> 1231869 (stub libintl.h):libs/libintl.s

libs_args=( )

libs_build() {
    cat << EOF > libintl.h
#ifndef LIBINTL_H
#define LIBINTL_H

#define textdomain(domain) ((char *)("messages"))

#define bindtextdomain(domain, dirname) ((char *)(dirname))
#define bind_textdomain_codeset(domain, codeset) ((char *)(codeset))

<<<<<<<< HEAD:libs/draft/libintl.s
    cmdlet.pkgconf libintl -lintl libiconv

    is_darwin && cmdlet.pkgconf libintl -framework CoreFoundation
|||||||| parent of 1231869 (stub libintl.h):libs/libintl.s
    cmdlet.pkgconf libintl -lintl
========
#define gettext(msgid) (msgid)
#define dgettext(domain, msgid) (msgid)
#define dcgettext(domain, msgid, cate) (msgid)
#define ngettext(msgid1, msgid2, n) ((n) == 1 ? (msgid1) : (msgid2))
#define dngettext(domain, msgid1, msgid2, n) ((n) == 1 ? (msgid1) : (msgid2))
#define dcngettext(domain, msgid1, msgid2, n, cate) ((n) == 1 ? (msgid1) : (msgid2))
>>>>>>>> 1231869 (stub libintl.h):libs/libintl.s

#endif
EOF

    cmdlet.pkginst libintl libintl.h
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
