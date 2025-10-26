# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
# shellcheck disable=SC2034
libs_desc="Parallel bzip2"
libs_lic='bzip2'
libs_ver=1.1.14
libs_url=(
    https://launchpad.net/pbzip2/1.1/1.1.13/+download/pbzip2-1.1.13.tar.gz
)
libs_sha=8fd13eaaa266f7ee91f85c1ea97c86d9c9cc985969db9059cdebcb1e1b7bdbe6
libs_dep=( bzip2 )

libs_args=(
)

libs_build() {
    CXXFLAGS+=" -Wno-reserved-user-defined-literal"

    # C++20 is required for char8_t in the patch.
    is_darwin && CXXFLAGS+=" -std=c++20" || CXXFLAGS+=" -std=c++2a"

    LDLIBS="$PREFIX/lib/libbz2.a"

    is_darwin && LDLIBS+=" -lc++" || LDLIBS+=" -lstdc++"

    make pbzip2 \
        PREFIX="'$PREFIX'"    \
        CXX="'$CC'"            \
        CXXFLAGS="'$CXXFLAGS $CPPFLAGS'" \
        LDFLAGS="'$LDFLAGS'"   \
        LDLIBS="'$LDLIBS'"

    cmdlet ./pbzip2 pbzip2 pbunzip2 pbzcat

    check pbzip2 --version

    caveats << EOF
static built pbzip2 @ $libs_ver

Usage:
    tar -cf - paths-to-archive | pbzip2 -c > archive.tar.bz2
    pbzip2 -d archive.tar.bz2  | tar -xf -

    OR

    tar -I pbzip2 -xf archive.tar.bz2 -C /tmp
    tar -I pbzip2 -cf archive.tar.bz2 -C /opt
EOF
}

# Fixes: error: implicit instantiation of undefined template 'std::char_traits<unsigned char>'
# https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes#C++-Standard-Library
__END__
--- a/BZ2StreamScanner.cpp
+++ b/BZ2StreamScanner.cpp
@@ -42,7 +42,7 @@ int BZ2StreamScanner::init( int hInFile, size_t inBuffCapacity )
 {
 	dispose();

-	CharType bz2header[] = "BZh91AY&SY";
+	CharType bz2header[] = u8"BZh91AY&SY";
 	// zero-terminated string
 	CharType bz2ZeroHeader[] =
 		{ 'B', 'Z', 'h', '9', 0x17, 0x72, 0x45, 0x38, 0x50, 0x90, 0 };
--- a/BZ2StreamScanner.h
+++ b/BZ2StreamScanner.h
@@ -20,7 +20,7 @@ namespace pbzip2
 class BZ2StreamScanner
 {
 public:
-	typedef unsigned char CharType;
+	typedef char8_t CharType;

 	static const size_t DEFAULT_IN_BUFF_CAPACITY = 1024 * 1024; // 1M
 	static const size_t DEFAULT_OUT_BUFF_LIMIT = 1024 * 1024;
