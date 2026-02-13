# shellcheck disable=SC2034
libs_desc="Popular GNU data compression program"

libs_lic=GPLv3+
libs_ver=1.14
libs_url=(
    https://ftpmirror.gnu.org/gnu/gzip/gzip-$libs_ver.tar.xz
    # mirrors
    https://ftp.gnu.org/gnu/gzip/gzip-$libs_ver.tar.xz
    https://mirrors.ustc.edu.cn/gnu/gzip/gzip-$libs_ver.tar.xz
)
libs_sha=01a7b881bd220bfdf615f97b8718f80bdfd3f6add385b993dcf6efd14e8c0ac6
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --without-selinux
    --disable-acl

    # always disable nls for single static executable, or
    #  => PREFIX/share/locale will hardcoded into executable
    --disable-nls

)

libs_build() {
    configure 

    make 

    # make check in mingw do not respect $EXEEXT
    is_mingw || make check

    pkginst libgzip gzip.h lzw.h lib/libgzip.a

    cmdlet.install gzip   
    cmdlet.install gunzip 
    cmdlet.install gzexe  
    cmdlet.install zcat   
    cmdlet.install zcmp   
    cmdlet.install zdiff  
    cmdlet.install zgrep  
    cmdlet.install zegrep 
    cmdlet.install zfgrep 
    cmdlet.install zmore  
    cmdlet.install zless  
    cmdlet.install znew   

    cmdlet.check gzip

    # simple test 
    echo "test" > foo && rm -f foo.gz
    run gzip foo                                || die "gzip compress failed."
    run gzip -t foo.gz                          || die "gzip integrity test failed."
    run gzip -l foo.gz | grep -Fwq foo          || die "gzip list contents failed."
    run gunzip -c foo.gz | grep -Eq "^test$"    || die "gunzip decompress failed."
    run zcat foo.gz | grep -Eq "^test$"         || die "zcat failed."

}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
