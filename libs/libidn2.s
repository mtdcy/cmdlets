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
    --disable-rpath

    --disable-doc
    --disable-gtk-doc
    --disable-gtk-doc-html

    --disable-shared
    --enable-static
)

libs_build() {
    # https://github.com/spack/spack/issues/23964
    export GTKDOCIZE=echo

    # hack gnulib error() function
    #  Fix: multiple definition of `error' when building git
    sed -i 's/^error (/_hack_gl_error (/' gl/error.c
    sed -i gl/error.in.h \
        -e 's/_GL_FUNCDECL_SYS (error,/_GL_FUNCDECL_SYS (_hack_gl_error,/g' \
        -e 's/_GL_CXXALIAS_SYS (error,/_GL_CXXALIAS_SYS (_hack_gl_error,/g'  \
        -e 's/return error (/return _hack_gl_error (/g' \
        -e '/_GL_CXXALIAS_SYS (_hack_gl_error/i #define error(...) _hack_gl_error(__VA_ARGS__)'

    configure &&

    make &&

    # check & install
    make check &&

    pkgfile libidn2 -- make install SUBDIRS=lib &&

    cmdlet  src/idn2 &&

    check   idn2 --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
