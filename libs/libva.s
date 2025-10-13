# shellcheck disable=SC2034
#
# shellcheck disable=SC2034

libs_lic=""
libs_ver=2.22.0
libs_url=https://github.com/intel/libva/releases/download/$libs_ver/libva-$libs_ver.tar.bz2
libs_sha=e3da2250654c8d52b3f59f8cb3f3d8e7fb1a2ee64378dbc400fbc5663de7edb8
libs_dep=(libdrm)

libs_args+=(
    --enable-static
    --disable-shared
    --disable-x11
    --disable-glx
    --disable-wayland
)

libs_build() {
    configure &&
    make &&
    make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
