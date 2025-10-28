# Pluggable Authentication Modules for Linux
#
# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.7.1
libs_url=https://github.com/linux-pam/linux-pam/releases/download/v1.7.1/Linux-PAM-1.7.1.tar.xz
libs_sha=21dbcec6e01dd578f14789eac9024a18941e6f2702a05cf91b28c232eeb26ab0
libs_dep=( libnsl libtirpc libxcrypt )

# configure args
libs_args=(
    --sysconfdir==/etc/
)

libs_build() {
    depends_on is_linux

    if test -d /lib/security; then
        libs_args+=( -Dsecuredir=/lib/security )
    else
        libs_args+=( -Dsecuredir=/lib/$(uname -m)-linux-gnu/security )
    fi

    meson setup build

    meson compile -C build --verbose

    pkgfile libpam -- meson install -C build
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
