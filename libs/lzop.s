# shellcheck disable=SC2034

libs_desc="lzop is a file compressor which is very similar to gzip."

libs_lic=GPLv2
libs_ver=1.04
libs_url=https://www.lzop.org/download/lzop-$libs_ver.tar.gz
libs_sha=7e72b62a8a60aff5200a047eea0773a8fb205caf7acbe1774d95147f305a2f41
libs_dep=(lzo)

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --enable-silent-rules

)

libs_build() {
    configure 

    make 

    make check 

    cmdlet.install src/lzop 

    cmdlet.check lzop --version
    
    echo "test" > foo && rm -f foo.lzo
    run lzop foo                                || die "lzop compress failed."
    run lzop -t foo.lzo                         || die "lzop integrity test failed."
    run lzop -l foo.lzo | grep -Fwq foo         || die "lzop list contents failed."
    run lzop -d -c foo.lzo | grep -Eq "^test$"  || die "lzop decompress failed."
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
