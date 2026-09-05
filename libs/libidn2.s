# International domain name library (IDNA2008, Punycode and TR46)

# shellcheck disable=SC2034
libs_lic='GPL-2.0-or-later|LGPL-3.0-or-later'
libs_ver=2.3.8
libs_url=https://ftpmirror.gnu.org/gnu/libidn/libidn2-$libs_ver.tar.gz
libs_sha=f557911bf6171621e1f72ff35f5b1825bb35b52ed45325dcdee931e5d3c0787a
libs_dep=(libiconv libunistring)

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --without-included-libunistring
    --with-libunistring-prefix="'$PREFIX'"

    --disable-nls

    --disable-doc
    --disable-gtk-doc
    --disable-gtk-doc-html

    --disable-shared
    --enable-static
)

libs_build() {
    # https://github.com/spack/spack/issues/23964
    export GTKDOCIZE=echo

    # https://gitlab.com/libidn/libidn2/-/issues/108
    AUTOPOINT=true autoreconf -fiv

    # ac_cv_func_error_at_line:
    #  fix error: undefined reference to `rpl_error'
    configure ac_cv_func_error_at_line=yes

    make

    # check & install
    make check

    cmdlet.pkgfile libidn2 -- make install SUBDIRS=lib

    cmdlet.install src/idn2

    cmdlet.check idn2 --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
