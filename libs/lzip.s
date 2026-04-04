libs_desc="LZMA lossless data compressor"
# shellcheck disable=SC2034

libs_lic=GPLv2+
libs_ver=1.26
libs_url=(
    https://download-mirror.savannah.gnu.org/releases/lzip/lzip-1.26.tar.lz
    https://mirror.kumi.systems/nongnu/lzip/lzip-1.26.tar.lz
)
libs_sha=1746f1e4ec4359a728692ce2db45641c9267b048aa13c044e9d581d50394713d
libs_dep=()

is_mingw && CXXFLAGS+='-D__USE_MINGW_ANSI_STDIO'

# non-standard configure
libs_args=(
    CXX="'$CXX'"
    CPPFLAGS="'$CPPFLAGS'"
    CXXFLAGS+="'$CXXFLAGS'" 
    LDFLAGS="'$LDFLAGS'"
)

libs_build() {
    configure 

    make 

    is_mingw || make check 

    cmdlet.install lzip

    # verify
    cmdlet.check lzip --version
    
    echo "test" > foo && rm -f foo.lz
    run lzip foo                                || die "lzip compress failed."
    run lzip -t foo.lz                          || die "lzip integrity test failed."
    run lzip --list foo.lz | grep -Fwq foo      || die "lzip list contents failed."
    run lzip -d -c foo.lz | grep -Eq "^test$"   || die "lzip decompress failed."
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
