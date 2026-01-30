# Network authentication protocol

# shellcheck disable=SC2034
libs_lic=''
libs_ver=1.22.2
libs_url=https://kerberos.org/dist/krb5/1.22/krb5-1.22.2.tar.gz
libs_sha=3243ffbc8ea4d4ac22ddc7dd2a1dc54c57874c40648b60ff97009763554eaf13
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
    #TOP_SUBDIRS=( util include lib build-tools plugins/kdb/db2 clients )
    TOP_SUBDIRS=( util include lib build-tools )
    sed -i 's/SUBDIRS/TOP_SUBDIRS/g' Makefile

    make TOP_SUBDIRS="'${TOP_SUBDIRS[*]}'"

    # Fix krb5-config, OR configure and cmake may not work
    # 1. replace hardcoded PREFIX, refer to helpers.sh:_pack()
    # 2. append eval to echo command
    # 3. drop rpath things
    # 4. drop -dynamic
    # 5. output static libraries
    sed -i build-tools/krb5-config      \
        -e 's/echo\s\+"\$DEF/eval &/'   \
        -e '/RPATH/d'                   \
        -e 's/-dynamic //g'             \
        -e 's/echo\s\+\$lib_flags/& -lkrb5support $LIBS $DL_LIB/'

    
    # fix pc: -lresolv for dns_open and dns_close
    #  krb5 put -lresolv in krb5-config instead of pc file, which cause
    #  some packages failed to build
    is_darwin && sed -i '/Libs:/s/$/& -lresolv/' build-tools/mit-krb5.pc

    pkgfile libkrb5 -- make install TOP_SUBDIRS="'${TOP_SUBDIRS[*]}'"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
