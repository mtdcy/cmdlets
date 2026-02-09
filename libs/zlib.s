#!/bin/bash
# A Massively Spiffy Yet Delicately Unobtrusive Compression Library
#   (Also Free, Not to Mention Unencumbered by Patents)

# shellcheck disable=SC2034
libs_name=zlib
libs_lic="zlib"
libs_ver=1.3.1
libs_url=(
    # has different sha vs office package
    https://mirrors.wikimedia.org/ubuntu/pool/main/z/zlib/zlib_${libs_ver%.*}.dfsg+really$libs_ver.orig.tar.gz
    #https://zlib.net/zlib-$libs_ver.tar.gz
)
libs_sha=60dd315c07f616887caa029408308a018ace66e3d142726a97db164b3b8f69fb

libs_deps=()

# configure args
libs_args=(
)

# resources: "url;sha"
libs_resources=

# patches
libs_patches=()

libs_build() {
    # non standard configure
    configure --static

    make CC="'$CC'" CFLAGS="'$CFLAGS'"

    cat <<EOF > zlib.pc
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
sharedlibdir=\${libdir}
includedir=\${prefix}/include

Name: zlib
Description: zlib compression library
Version: $libs_ver

Requires:
Libs: -L\${libdir} -L\${sharedlibdir} -lz
Cflags: -I\${includedir}
EOF

    cmdlet minigzip &&

    pkginst libz \
            include zlib.h zconf.h \
            lib libz.a \
            lib/pkgconfig zlib.pc &&

    # shellcheck source=SCRIPTDIR/libs.sh
    check minigzip

}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
