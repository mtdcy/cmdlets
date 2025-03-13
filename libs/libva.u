# shellcheck disable=SC2034
#
# shellcheck disable=SC2034

upkg_lic=""
upkg_ver=2.22.0
upkg_url=https://github.com/intel/libva/releases/download/$upkg_ver/libva-$upkg_ver.tar.bz2
upkg_sha=e3da2250654c8d52b3f59f8cb3f3d8e7fb1a2ee64378dbc400fbc5663de7edb8
upkg_dep=(libdrm)

upkg_args+=(
    --enable-static
    --disable-shared
    --disable-x11
    --disable-glx
    --disable-wayland
)

upkg_static() {
    configure &&
    make &&
    make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
