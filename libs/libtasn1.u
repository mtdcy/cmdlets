
#
# shellcheck disable=SC2034
upkg_lic='LGPL'
upkg_ver=4.20.0
upkg_url=https://ftpmirror.gnu.org/gnu/libtasn1/libtasn1-$upkg_ver.tar.gz
upkg_sha=92e0e3bd4c02d4aeee76036b2ddd83f0c732ba4cda5cb71d583272b23587a76c

upkg_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-shared
    --enable-static
)

upkg_static() {
    configure && make &&

    make install &&

    library tasn1 \
        include         lib/includes/libtasn1.h \
        lib             lib/.libs/libtasn1.a \
        lib/pkgconfig   lib/libtasn1.pc &&

    cmdlet src/asn1Coding &&
    cmdlet src/asn1Decoding &&
    cmdlet src/asn1Parser
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
