# Hardware accelerated video processing library (Linux)

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.22.0
libs_url=https://github.com/intel/libva/releases/download/$libs_ver/libva-$libs_ver.tar.bz2
libs_sha=e3da2250654c8d52b3f59f8cb3f3d8e7fb1a2ee64378dbc400fbc5663de7edb8

is_linux && libs_dep=(libdrm wayland)

libs_args+=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    # avoid hardcode PREFIX into libraries
    --sysconfdir=/etc
    --localstatedir=/var
    --with-drivers-path=/usr/lib/dri

    # API support
    --enable-drm        # VA/DRM
    --enable-wayland    # VA/Wayland
    --disable-x11       # VA/X11
    --disable-glx       # VA/GLX

    # disable features
    --disable-docs

    # static only
    --enable-static
    --disable-shared
)

libs_build() {

    configure && make || return $?

    pkgfile libva -- make install
}

libs_depends is_linux

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
