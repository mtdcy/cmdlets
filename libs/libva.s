# Hardware accelerated video processing library (Linux)

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.23.0
libs_url=https://github.com/intel/libva/releases/download/$libs_ver/libva-$libs_ver.tar.bz2
libs_sha=9ac190a87017bfd49743248f5df7cf3b18a99a9962175caf6bbe3f1ea41b6dbb

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

libs.depends is_linux

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
