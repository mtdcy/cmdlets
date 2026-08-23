# stub libintl.h
#
# XXX: we do not need internationalization (i18n) and localization (l10n), but some program has no option disable it.
#  => create a stub libintl.h

# shellcheck disable=SC2034
libs_lic=BSD
libs_ver=1.0
libs_url=
libs_sha=

libs_deps=()

libs_args=()

libs_build() {
    cat << EOF > libintl.h
#ifndef _LIBINTL_H
#define _LIBINTL_H

#ifdef __cplusplus
extern "C" {
#endif

extern char *textdomain(const char *domainname);
extern char *bindtextdomain(const char *domainname, const char *dirname);
extern char *bind_textdomain_codeset(const char *domainname, const char *codeset);

extern char *gettext(const char *msgid);
extern char *dgettext(const char *domainname, const char *msgid);
extern char *dcgettext(const char *domainname, const char *msgid, int category);

extern char *ngettext(const char *msgid1, const char *msgid2, unsigned long int n);
extern char *dngettext(const char *domainname, const char *msgid1, const char *msgid2, unsigned long int n);
extern char *dcngettext(const char *domainname, const char *msgid1, const char *msgid2, unsigned long int n, int category);

#ifdef __cplusplus
}
#endif

#endif // _LIBINTL_H
EOF

    cat << EOF > libintl.c
#include "libintl.h"

char *textdomain(const char *domainname) {
    (void)domainname; /* 显式忽略未使用的变量，防止产生编译器警告 */
    return (char *)("messages");
}

char *bindtextdomain(const char *domainname, const char *dirname) {
    (void)domainname;
    return (char *)(dirname);
}

char *bind_textdomain_codeset(const char *domainname, const char *codeset) {
    (void)domainname;
    return (char *)(codeset);
}

char *gettext(const char *msgid) {
    return (char *)(msgid);
}

char *dgettext(const char *domainname, const char *msgid) {
    (void)domainname;
    return (char *)(msgid);
}

char *dcgettext(const char *domainname, const char *msgid, int category) {
    (void)domainname;
    (void)category;
    return (char *)(msgid);
}

char *ngettext(const char *msgid1, const char *msgid2, unsigned long int n) {
    return (char *)((n == 1) ? msgid1 : msgid2);
}

char *dngettext(const char *domainname, const char *msgid1, const char *msgid2, unsigned long int n) {
    (void)domainname;
    return (char *)((n == 1) ? msgid1 : msgid2);
}

char *dcngettext(const char *domainname, const char *msgid1, const char *msgid2, unsigned long int n, int category) {
    (void)domainname;
    (void)category;
    return (char *)((n == 1) ? msgid1 : msgid2);
}
EOF

    "$CC" $CFLAGS $CPPFLAGS -c libintl.c -o libintl.o
    "$AR" cr libintl.a libintl.o

    cmdlet.pkgconf libintl0.pc -lintl # used to force link our libintl
    cmdlet.pkgconf libintl.pc -lintl
    cmdlet.pkgconf intl.pc -lintl

    cmdlet.pkginst libintl libintl.h libintl.a libintl0.pc libintl.pc intl.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
