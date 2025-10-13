# Generic-purpose lossless compression algorithm by Google
#
# shellcheck disable=SC2034

libs_lic="MIT"
libs_ver=1.1.0
libs_url="https://github.com/google/brotli/archive/refs/tags/v$libs_ver.tar.gz"
libs_zip=brotli-$libs_ver.tar.gz
libs_sha=e720a6ca29428b803f4ad165371771f5398faba397edf6778837a18599ea13ff
libs_dep=()

libs_args=(
    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    cmake . &&

    make &&

#   # fix pc for static link
#   if is_linux; then
#       echo "Libs.private: -lm" >> libbrotlicommon.pc
#   fi &&

    make test &&

    library libbrotli \
            include/brotli  c/include/brotli/*.h \
            lib             libbrotli*.a \
            lib/pkgconfig   libbrotli*.pc &&

    cmdlet brotli &&

    check brotli --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
