libs_desc="LZMA lossless data compressor"
# shellcheck disable=SC2034

libs_lic=GPLv2+
libs_ver=1.25
libs_url=http://download.savannah.gnu.org/releases/lzip/lzip-$libs_ver.tar.gz
libs_sha=09418a6d8fb83f5113f5bd856e09703df5d37bae0308c668d0f346e3d3f0a56f
libs_dep=()

is_mingw && CXXFLAGS+= '-D__USE_MINGW_ANSI_STDIO'

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
