# Network authentication protocol

# shellcheck disable=SC2034
libs_lic=''
libs_ver=1.22.1
libs_url=https://kerberos.org/dist/krb5/1.22/krb5-1.22.1.tar.gz
libs_sha=1a8832b8cad923ebbf1394f67e2efcf41e3a49f460285a66e35adec8fa0053af
libs_dep=( openssl libedit )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-nls
    --without-system-verto
    --without-keyutils

    --disable-shared
    --enable-static
)

libs_build() {
    # macOS has krb5
    #depends_on is_linux

    cd src || die

    ## force static
    #sed -i configure                             \
    #    -e 's/CC_LINK_SHARED/CC_LINK_STATIC/g'   \
    #    -e 's/CXX_LINK_SHARED/CXX_LINK_STATIC/g' \

    configure

    # cc_initialize is only for _WIN32, but configure set it for macOS.
    # refer winccld and stdcc in ccapi for details
    #  => is this a mistake or bug?
    sed -i '/USE_CCAPI_MACOS/d' include/autoconf.h

    # build only static client libraries

    # edit only top SUBDIRS
    TOP_SUBDIRS=( util include lib build-tools )
    sed -i 's/SUBDIRS/TOP_SUBDIRS/g' Makefile

    make TOP_SUBDIRS="'${TOP_SUBDIRS[*]}'"

    # no krb5-config
    sed -i '/INSTALL.*krb5-config/d' build-tools/Makefile

    pkgfile libkrb5 -- make install TOP_SUBDIRS="'${TOP_SUBDIRS[*]}'"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
