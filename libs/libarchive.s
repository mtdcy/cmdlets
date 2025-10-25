# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
# shellcheck disable=SC2034
libs_desc="Multi-format archive and compression library"
libs_lic='BSD-2-Clause'
libs_ver=3.8.2
libs_url=(
    https://www.libarchive.org/downloads/libarchive-$libs_ver.tar.xz
)
libs_sha=db0dee91561cbd957689036a3a71281efefd131d35d1d98ebbc32720e4da58e2
libs_dep=( libb2 lz4 xz zstd bzip2 expat zlib libiconv )

libs_args=(
    # our libiconv has no pc file
    -DENABLE_ICONV=ON
    -DLIBICONV_PATH="'$PREFIX'"

    -DENABLE_LZO=OFF        # Use lzop binary instead of lzo2 due to GPL

    # hashing options
    -DENABLE_EXPAT=ON       # best xar hashing option
    -DENABLE_NETTLE=OFF     # xar hashing option but GPLv3
    -DENABLE_LIBXML2=OFF    # xar hashing option but tricky dependencies
    -DENABLE_OPENSSL=OFF    # mtree hashing now possible without OpenSSL

    # no executables
    -DENABLE_TAR=OFF
    -DENABLE_CPIO=OFF
    -DENABLE_CAT=OFF
    -DENABLE_UNZIP=OFF

    -DENABLE_ACL=OFF
    -DENABLE_TEST=OFF

    # static only
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_STATIC_LIBS=ON
)

libs_build() {
    # XXX: configure build system has problem to link with libiconv.a

    cmake -S . -B build

    cmake --build build

    # fix for libiconv
    sed -i '/^Libs.private/s/$/& -liconv/' build/build/pkgconfig/libarchive.pc || die

    pkgfile libarchive -- cmake --install build
}
