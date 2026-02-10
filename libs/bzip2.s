# bzip2 is a freely available, patent free (see below), high-quality data compressor.
#
# shellcheck disable=SC2034

libs_lic="BSD-style"
libs_ver=1.0.8
libs_url=https://sourceware.org/pub/bzip2/bzip2-$libs_ver.tar.gz
#https://ftp.osuosl.org/pub/clfs/conglomeration/bzip2/bzip2-$libs_ver.tar.gz
libs_sha=ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269

libs_build() {
    hack.makefile Makefile CC AR RANLIB CFLAGS LDFLAGS

    make bzip2

    # add file extension for windows
    is_mingw && mv bzip2 bzip2.exe

    # will not pass with mingw
    is_mingw || make test

    pkgconf bz2     -lbz2
    pkgconf bzip2   -lbz2
    pkgconf libbz2  -lbz2

    # install lib and headers
    cmdlet.pkginst libbz2 bzlib.h libbz2.a bz2.pc bzip2.pc libbz2.pc

    # install cmdlets and symlinks
    cmdlet.install bzip2 bzip2 bunzip2 bzcat
    cmdlet.check bzip2 --help

    # no shell scripts for windows
    if ! is_mingw; then
        cmdlet.install bzdiff bzdiff bzcmp
        cmdlet.install bzgrep bzgrep bzegrep bzfgrep
        cmdlet.install bzmore bzmore bzless
    fi
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
