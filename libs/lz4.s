# Extremely Fast Compression algorithm
# shellcheck disable=SC2034

libs_name=lz4
libs_lic="BSD-2-Clause"
libs_ver=1.10.0
libs_url=https://github.com/lz4/lz4/releases/download/v$libs_ver/lz4-$libs_ver.tar.gz
libs_sha=537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b
libs_dep=()

libs_args=(
    PREFIX="'$PREFIX'"

    CC="'$CC'"
    USERCFLAGS="'$CFLAGS'"
    LDFLAGS="'$LDFLAGS'"

    BUILD_SHARED=no
    BUILD_STATIC=yes
)

libs_build() {
    make "${libs_args[@]}"

    cmdlet.pkgfile liblz4 -- make install -C lib "${libs_args[@]}"

    cmdlet.install programs/lz4 lz4 unlz4 lz4c lz4cat

    cmdlet.check lz4 --version
    
    echo "test" > foo && rm -f foo.lz4
    run lz4 foo                                 || die "lz4 compress failed."
    run lz4 -t foo.lz4                          || die "lz4 integrity test failed."
    run lz4 --list foo.lz4 | grep -Fwq foo      || die "lz4 list contents failed."
    run lz4 -d -c foo.lz4 | grep -Eq "^test$"   || die "lz4 decompress failed."
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
