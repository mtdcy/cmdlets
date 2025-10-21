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

    # our libxml2 has no xml2-config
    #  set libxml2 prefix explicitly to avoid call host xml2-config
    --with-libxml-prefix="'$PREFIX'"

    # add crypto to exslt
    --with-crypto

    --disable-debug
    --without-python # python bindings
    --without-debugger
    --without-profiler

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    LIBXML_CFLAGS="$(pkg-config --cflags libxml-2.0)"
    LIBXML_LIBS="$(pkg-config --libs libxml-2.0)"

    export LIBXML_CFLAGS LIBXML_LIBS

    # link static libexslt by default
    sed -i '/Libs.private/s/$/ -lexslt/' libxslt.pc.in

    configure

    make

    pkgfile "$libs_name" -- make install bin_PROGRAMS=

    cmdlet ./xsltproc/xsltproc

    check xsltproc --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
