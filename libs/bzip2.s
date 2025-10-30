# bzip2 is a freely available, patent free (see below), high-quality data compressor.
#
# shellcheck disable=SC2034

libs_lic="BSD-style"
libs_ver=1.0.8
libs_url=https://sourceware.org/pub/bzip2/bzip2-$libs_ver.tar.gz
#https://ftp.osuosl.org/pub/clfs/conglomeration/bzip2/bzip2-$libs_ver.tar.gz
libs_sha=ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269

libs_build() {
    sed -e '/^CC=gcc/d'            \
        -e '/^AR=ar/d'             \
        -e '/^RANLIB=ranlib/d'     \
        -e '/^LDFLAGS=/d'          \
        -e 's/^CFLAGS=/CFLAGS+=/g' \
        -i Makefile

    make all test &&

    # install lib and headers
    pkginst libbz2 bzlib.h libbz2.a

    #
    pkgconf bz2     -lbz2
    pkgconf bzip2   -lbz2
    pkgconf libbz2  -lbz2

    # install cmdlets and symlinks
    cmdlet bzip2 bzip2 bunzip2 bzcat &&
    cmdlet bzdiff bzdiff bzcmp &&
    cmdlet bzgrep bzgrep bzegrep bzfgrep &&
    cmdlet bzmore bzmore bzless &&

    check bzip2
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
