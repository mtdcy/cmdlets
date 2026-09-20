# shellcheck disable=SC2034
libs_desc="Popular GNU data compression program"

libs_lic=GPLv3+
libs_ver=1.15
libs_rev=1
libs_url=(
    https://ftpmirror.gnu.org/gnu/gzip/gzip-$libs_ver.tar.xz
    # mirrors
    https://ftp.gnu.org/gnu/gzip/gzip-$libs_ver.tar.xz
    https://mirrors.ustc.edu.cn/gnu/gzip/gzip-$libs_ver.tar.xz
)
libs_sha=9aa0cc780dec156b8282844833b342ab7cb08c25d2cd9a1869cdd0df31deff48
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
    if is_mingw || is_cygwin; then
        slogw "skip check"
    else
        make check
    fi

    cmdlet.pkginst libgzip gzip.h lzw.h lib/libgzip.a

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

    # simple test
    echo "test" > foo && rm -f foo.gz
    cmdlet.verify gzip << EOF
    gzip --version
    gzip foo                                || die "gzip compress failed."
    gzip -t foo.gz                          || die "gzip integrity test failed."
    gzip -l foo.gz | grep -Fwq foo          || die "gzip list contents failed."
    gunzip -c foo.gz | grep -Eq "^test$"    || die "gunzip decompress failed."
    zcat foo.gz | grep -Eq "^test$"         || die "zcat failed."
EOF
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
