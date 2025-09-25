# BSD-3-Clause
#
# shellcheck disable=SC2034

upkg_lic="BSD"
upkg_ver=0.1.6
upkg_url=https://downloads.sourceforge.net/opencore-amr/opencore-amr-$upkg_ver.tar.gz
upkg_sha=483eb4061088e2b34b358e47540b5d495a96cd468e361050fae615b1809dc4a1

upkg_args=(
    --enable-amrnb-decoder
    --enable-amrnb-encoder
    --disable-shared
    --enable-static
)

upkg_static() {
    configure && make &&

    library opencore-amrnb \
        include/opencore-amrnb amrnb/*.h \
        lib amrnb/.libs/*.a \
        lib/pkgconfig amrnb/*.pc &&
    
    library opencore-amrwb \
        include/opencore-amrwb amrwb/*.h \
        lib amrwb/.libs/*.a \
        lib/pkgconfig amrwb/*.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
