# Library and utilities for processing GIFs

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=5.2.2
libs_url=https://downloads.sourceforge.net/project/giflib/giflib-$libs_ver.tar.gz
libs_sha=be7ffbd057cadebe2aa144542fd90c6838c6a083b5e8a9048b8ee3b66b29d5fb
libs_dep=()

libs_build() {
    make CFLAGS="'$CFLAGS'" LDFLAG="'$LDFLAGS'" gifecho &&

    cat > gif.pc << EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: gif
Version: $libs_ver

Libs: -L\${libdir} -lgif
Cflags: -I\${includedir}
EOF

    library gif \
            include         gif_lib.h \
            lib             libgif.a \
            lib/pkgconfig   gif.pc &&

    cmdlet gifecho &&

    check gifecho -h
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
