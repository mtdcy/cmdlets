# Ping-like tool for HTTP requests

# fatal error: sys/socket.h: No such file or directory
#  depends on posix socket
libs_targets=( linux macos )

# shellcheck disable=SC2034
libs_lic='AGPL'
libs_ver=4.4.0
libs_url=https://github.com/folkertvanheusden/HTTPing/archive/refs/tags/v4.4.0.tar.gz
libs_sha=87fa2da5ac83c4a0edf4086161815a632df38e1cc230e1e8a24a8114c09da8fd
libs_dep=( ncurses openssl )

# enable TCP Fast Open on macOS, upstream pr ref, https://github.com/folkertvanheusden/HTTPing/pull/48
is_darwin && libs_patches=(
    https://github.com/folkertvanheusden/HTTPing/commit/79236affb75667cf195f87a58faaebe619e7bfd4.patch?full_index=1
)

libs_args=(
    -DUSE_SSL=ON

    -DUSE_GETTEXT=OFF

    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    cmake -S . -B build

    cmake --build build

    cmdlet ./build/httping

    check httping --version

    # macOS FIXME: SSL certificate validation failed: unable to get local issuer certificate
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
