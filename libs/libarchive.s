# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
# shellcheck disable=SC2034
libs_desc="Multi-format archive and compression library"
libs_lic='BSD-2-Clause'
libs_ver=3.8.5
libs_url=https://www.libarchive.org/downloads/libarchive-$libs_ver.tar.xz
libs_sha=d68068e74beee3a0ec0dd04aee9037d5757fcc651591a6dcf1b6d542fb15a703

libs_deps=( libb2 lz4 xz zstd bzip2 expat zlib libiconv pcre2 )

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-libiconv

    --without-lzo2      # Use lzop binary instead of lzo2 due to GPL

    # programs
    --enable-bsdtar=static
    --enable-bsdcpio=static
    --enable-bsdunzip=static

    # disabled features
    --disable-largefile
    --without-selinux
    --disable-acl
    --disable-nls

    # static only
    --disable-shared
    --enable-static
)
   
# use pcre2 intead of libc/libgnurx regex for all targets
is_listed pcre2 libs_deps && libs_args+=( --enable-posix-regex-lib=libpcre2posix )

# hashing options
is_listed expat   libs_deps && libs_args+=( --with-expat   ) || libs_args+=( --without-expat   ) # best xar hashing option
is_listed libxml2 libs_deps && libs_args+=( --with-xml2    ) || libs_args+=( --without-xml2    ) # xar hashing option but tricky dependencies
is_listed nettle  libs_deps && libs_args+=( --with-nettle  ) || libs_args+=( --without-nettle  ) # xar hashing option but GPLv3
is_listed openssl libs_deps && libs_args+=( --with-openssl ) || libs_args+=( --without-openssl ) # mtree hashing now possible without OpenSSL

# archive files
is_listed zlib     libs_deps && libs_args+=( --with-zlib   ) || libs_args+=( --without-zlib   )
is_listed libb2    libs_deps && libs_args+=( --with-libb2  ) || libs_args+=( --without-libb2  )
is_listed bzip2    libs_deps && libs_args+=( --with-bz2lib ) || libs_args+=( --without-bz2lib )
is_listed lz4      libs_deps && libs_args+=( --with-lz4    ) || libs_args+=( --without-lz4    )
is_listed xz       libs_deps && libs_args+=( --with-lzma   ) || libs_args+=( --without-lzma   )
is_listed zstd     libs_deps && libs_args+=( --with-zstd   ) || libs_args+=( --without-zstd   )

is_listed libiconv libs_deps && libs_args+=( --with-iconv  ) || libs_args+=( --without-iconv  )

# cmake build can't not handle static libraries properly
libs_build() {
    # configure has problem with static pcre2
    export LIBS="$($PKG_CONFIG --libs-only-l libpcre2-posix)"

    bootstrap

    configure

    make

    cmdlet.pkgfile libarchive -- make install bin_PROGRAMS= man_MANS=

    for x in tar cpio; do
        cmdlet.install bsd$x
    done

    cmdlet.check bsdtar --help
}

__END__
# ./configure: line 4269: -D__MINGW_USE_VC2005_COMPAT: command not found

--- configure.ac.orig	2026-02-19 12:18:24.620009233 +0800
+++ configure.ac	2026-02-19 12:18:57.405844913 +0800
@@ -104,7 +104,7 @@
 dnl Defines that are required for specific platforms (e.g. -D_POSIX_SOURCE, etc)
 PLATFORMCPPFLAGS=
 case "$host_os" in
-  *mingw* ) PLATFORMCPPFLAGS=-D__USE_MINGW_ANSI_STDIO -D__MINGW_USE_VC2005_COMPAT ;;
+  *mingw* ) PLATFORMCPPFLAGS="-D__USE_MINGW_ANSI_STDIO -D__MINGW_USE_VC2005_COMPAT" ;;
 esac
 AC_SUBST(PLATFORMCPPFLAGS)
