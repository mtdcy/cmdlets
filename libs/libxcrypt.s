# Extended crypt library for descrypt, md5crypt, bcrypt, and others
#
# shellcheck disable=SC2034
libs_lic="LGPLv2.1+"
libs_ver=4.5.2
libs_url=https://github.com/besser82/libxcrypt/releases/download/v$libs_ver/libxcrypt-$libs_ver.tar.xz
libs_sha=71513a31c01a428bccd5367a32fd95f115d6dac50fb5b60c779d5c7942aec071

libs_deps=()

libs_args=(
    # static only
    --enable-static --disable-shared

    --disable-obsolete-api
    --disable-xcrypt-compat-files
    --disable-failure-tokens
    --disable-valgrind
)

is_cygwin && libs_args+=(--disable-symvers)

libs_build() {
    configure

    make

    cmdlet.pkgfile libxcrypt -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
