# C XSLT library for GNOME
#
# shellcheck disable=SC2034
libs_lic="X11"
libs_ver=1.1.43
libs_url=https://github.com/GNOME/libxslt/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=e491bb8f11bd43c5da323c66f696b6e7b59d767c446053a7cbd8e805256bd9cb
libs_dep=( libxml2 libgcrypt libgpg-error )

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --with-pic

    # add crypto to exslt
    --with-crypto

    # search xml2-config in
    --with-libxml-prefix="'$PREFIX'"

    --disable-debug
    --without-python # python bindings
    --without-debugger
    --without-profiler

    # static only
    --disable-shared
    --enable-static
)

libs_build() {

    configure

    make

    # link static libexslt by default
    #  => fix `xsltApplyStylesheet() failed' for some programs
    pkgconf libxslt.pc -lexslt

    # install only libraries
    pkgfile "$libs_name" -- make install \
        SUBDIRS="'libxslt libexslt'"     \
        bin_PROGRAMS=                    \
        bin_SCRIPTS=                     \

    cmdlet.install  ./xsltproc/xsltproc
    cmdlet.check    xsltproc --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
