# shellcheck disable=SC2034

libs_name=lzip
libs_desc="LZMA lossless data compressor"

libs_lic='GPL-2.0-or-later'
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
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
