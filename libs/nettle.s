# Nettle is a cryptographic library that is designed to fit easily in more or less any context: In crypto toolkits for object-oriented languages.
# shellcheck disable=SC2034
libs_lic='LGPL|GPL'
libs_ver=3.9.1
libs_url=https://ftpmirror.gnu.org/gnu/nettle/nettle-$libs_ver.tar.gz
libs_sha=ccfeff981b0ca71bbd6fbcb054f407c60ffb644389a5be80d6716d5b550c6ce3
libs_dep=(gmp)

libs_args=(
    --libdir=$PREFIX/lib    # default install to lib64

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    # fix build with musl-gcc
    sed -i '/CC_FOR_BUILD/s/\$</$(CFLAGS) $(LDFLAGS) &/' Makefile.in

    configure && make && make check || return $?

    pkgfile libnettle -- make install-static install-headers install-pkgconfig &&

    cmdlet ./tools/pkcs1-conv           &&
    cmdlet ./tools/sexp-conv            &&
    cmdlet ./tools/nettle-hash          &&
    cmdlet ./tools/nettle-pbkdf2        &&
    cmdlet ./tools/nettle-lfib-stream
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
