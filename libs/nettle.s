# Nettle is a cryptographic library that is designed to fit easily in more or less any context: In crypto toolkits for object-oriented languages.
# shellcheck disable=SC2034
upkg_lic='LGPL|GPL'
upkg_ver=3.9.1
upkg_url=https://ftpmirror.gnu.org/gnu/nettle/nettle-$upkg_ver.tar.gz
upkg_sha=ccfeff981b0ca71bbd6fbcb054f407c60ffb644389a5be80d6716d5b550c6ce3
upkg_dep=(gmp)

upkg_args=(
    --libdir=$PREFIX/lib    # default install to lib64
    --disable-shared
    --enable-static
)

upkg_static() {
    configure && make &&

    #make install
    make config.h &&

    library nettle                               \
        include/nettle  *.h                      \
        lib             libnettle.a libhogweed.a \
        lib/pkgconfig   nettle.pc hogweed.pc &&

    cmdlet tools/pkcs1-conv           &&
    cmdlet tools/sexp-conv            &&
    cmdlet tools/nettle-hash          &&
    cmdlet tools/nettle-pbkdf2        &&
    cmdlet tools/nettle-lfib-stream
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
