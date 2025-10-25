# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
# shellcheck disable=SC2034
libs_desc="Multi-format archive and compression library"
libs_lic='BSD-2-Clause'
libs_ver=3.8.2
libs_url=(
    https://www.libarchive.org/downloads/libarchive-$libs_ver.tar.xz
)
libs_sha=db0dee91561cbd957689036a3a71281efefd131d35d1d98ebbc32720e4da58e2
libs_dep=( libb2 lz4 xz zstd bzip2 expat zlib )

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-pic

    # FIXME: missing iconv.pc
    --without-libiconv

    --without-lzo2      # Use lzop binary instead of lzo2 due to GPL

    # hashing options
    --with-expat        # best xar hashing option
    --without-nettle    # xar hashing option but GPLv3
    --without-xml2      # xar hashing option but tricky dependencies
    --without-openssl   # mtree hashing now possible without OpenSSL

    --without-selinux
    --disable-acl

    # always disable nls for single static executable
    --disable-nls

    # static only
    --disable-shared
    --enable-static

    --disable-largefile
)

libs_build() {
    configure

    make

    pkgfile libarchive -- make install
}
