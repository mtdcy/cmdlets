libs_desc="LZMA lossless data compressor"
# shellcheck disable=SC2034

libs_lic=GPLv2+
libs_ver=1.25
libs_url=(
    https://download-mirror.savannah.gnu.org/releases/lzip/lzip-1.25.tar.lz
    https://mirror.kumi.systems/nongnu/lzip/lzip-1.25.tar.lz
)
libs_sha=04d6ad5381e1763a0993cd20fe113b1aeb5ab59077fe85b1aec2268c6892b7a0
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
