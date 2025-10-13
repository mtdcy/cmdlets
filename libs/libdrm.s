# Library for accessing the direct rendering manager

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.4.126
libs_url=https://dri.freedesktop.org/libdrm/libdrm-$libs_ver.tar.xz
libs_sha=6cab16d4d259b6abc9f485233863454114a3c307eca806679aad3edbe967bf42

libs_args=(
    -Dudev=false
    -Dcairo-tests=disabled
    -Dvalgrind=disabled
)

libs_build() {
    is_darwin && {
        slogw "*****" "**** Not supported on $OSTYPE! ****"
        exit 0
    }

    mkdir -pv build && cd build &&
    meson setup .. &&
    ninja &&

    cd - &&

    library libdrm                                                \
            include         libsync.h xf86drm.h xf86drmMode.h     \
            include/libdrm  include/drm/*.h radeon/*.h amdgpu/*.h \
            include/libdrm/nouveau nouveau/*.h                    \
            include/libdrm/nouveau/nvif nouveau/nvif/*.h          \
            lib             build/libdrm.a                        \
                            build/nouveau/libdrm_nouveau.a        \
                            build/radeon/libdrm_radeon.a          \
                            build/amdgpu/libdrm_amdgpu.a          \
            lib/pkgconfig   build/meson-private/*.pc              \
            share/libdrm    data/amdgpu.ids
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
