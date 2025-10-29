# Minimalistic client for Redis

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.3.0
libs_url=https://github.com/redis/hiredis/archive/refs/tags/v1.3.0.tar.gz
libs_sha=25cee4500f359cf5cad3b51ed62059aadfc0939b05150c1f19c7e2829123631c
libs_dep=( openssl )

libs_args=(
)

libs_build() {
    # no shared libraries
    sed -i Makefile \
        -e '/^install:/s/\$(DYLIBNAME)//' \
        -e '/\$(DYLIBNAME)/d' \
        -e '/^install-ssl:/s/\$(SSL_DYLIBNAME)//' \
        -e '/\$(SSL_DYLIBNAME)/d' \

    pkgfile libhiredis -- make install PREFIX="'$PREFIX'" USE_SSL=1
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
