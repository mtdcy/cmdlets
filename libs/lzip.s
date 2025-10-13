# shellcheck disable=SC2034

libs_name=lzip
libs_desc="LZMA lossless data compressor"

libs_lic='GPL-2.0-or-later'
libs_ver=1.24.1
libs_url=http://download.savannah.gnu.org/releases/lzip/lzip-$libs_ver.tar.gz
libs_sha=30c9cb6a0605f479c496c376eb629a48b0a1696d167e3c1e090c5defa481b162
libs_dep=()

libs_args=(
)

libs_build() {
    # non-standard configure
    configure \
        CXX=\"$CXX\" \
        CXXFLAGS=\"$CXXFLAGS\" \
        CPPFLAGS=\"$CPPFLAGS\" \
        LDFLAGS=\"$LDFLAGS\" &&

    make &&

    make check &&

    cmdlet lzip &&

    # verify
    check lzip --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
