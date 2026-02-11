# HTTP(S) server and reverse proxy, and IMAP/POP3 proxy server
#
# shellcheck disable=SC2034,SC2154
libs_lic="BSD-2-Clause"
libs_ver=1.29.5
libs_url=https://nginx.org/download/nginx-$libs_ver.tar.gz
libs_sha=6744768a4114880f37b13a0443244e731bcb3130c0a065d7e37d8fd589ade374
libs_dep=( zlib pcre2 libxcrypt openssl libxml2 libxslt libgd )

WITH_GEOIP2=0

NGX_GEOIP2_VER=3.4
NGX_FANCYINDEX_VER=0.5.2
libs_resources=(
    "https://github.com/leev/ngx_http_geoip2_module/archive/$NGX_GEOIP2_VER.tar.gz;ad72fc23348d715a330994984531fab9b3606e160483236737f9a4a6957d9452"
    "https://github.com/aperezdc/ngx-fancyindex/archive/v$NGX_FANCYINDEX_VER.tar.gz;c3dd84d8ba0b8daeace3041ef5987e3fb96e9c7c17df30c9ffe2fe3aa2a0ca31"
)

libs_args=(
    --with-cc="'$CC'"
    --with-cpp="'$CPP'"

    --conf-path=/etc/nginx/nginx.conf

    # runtime paths
    --pid-path=/var/run/nginx.pid
    --lock-path=/var/run/nginx.lock
    --http-client-body-temp-path=/var/run/nginx/body
    --http-proxy-temp-path=/var/run/nginx/proxy
    --http-fastcgi-temp-path=/var/run/nginx/fastcgi
    --http-uwsgi-temp-path=/var/run/nginx/uwsgi
    --http-scgi-temp-path=/var/run/nginx/scgi

    # log path
    --http-log-path=/var/log/nginx/access.log
    --error-log-path=/var/log/nginx/error.log

    --with-compat
    --with-debug
    --with-ipv6

    --with-pcre
    --with-pcre-jit

    # http modules
    --with-http_v2_module
    --with-http_v3_module
    --with-http_ssl_module
    --with-http_realip_module
    --with-http_addition_module
    --with-http_xslt_module
    --with-http_image_filter_module
    --with-http_sub_module
    --with-http_dav_module
    --with-http_flv_module
    --with-http_mp4_module
    --with-http_gunzip_module
    --with-http_gzip_static_module
    --with-http_auth_request_module
    --with-http_random_index_module
    --with-http_secure_link_module
    --with-http_degradation_module
    --with-http_slice_module
    --with-http_stub_status_module

    #--with-http_perl_module

    # streams
    --with-stream
    --with-stream_realip_module
    --with-stream_ssl_module
    --with-stream_ssl_preread_module

    # mail
    --with-mail
    --with-mail_ssl_module

    # fancyindex
    --add-module=ngx-fancyindex-$NGX_FANCYINDEX_VER
)

is_mingw || libs_args+=( --with-threads )

# geoip2: requires maxminddb
if [ $WITH_GEOIP2 -ne 0 ]; then
    libs_dep+=( libmaxminddb )
    libs_args+=(
        --add-module=ngx_http_geoip2_module-$NGX_GEOIP2_VER
        --with-http_geoip_module
        --with-stream_geoip_module
    )
fi

is_mingw && libs_args+=( --crossbuild=win32 )

libs_build() {
    # nginx config for shared only, we have to add static libraries manually
    # append libexslt: try fix xsltApplyStylesheet() failed
    #  => exsltRegisterAll()
    libs.requires zlib libpcre2-8 libxcrypt openssl gdlib libexslt

    libs_args+=(
        # for NGX_CC_OPT
        --with-cc-opt="'$CFLAGS -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2'"
        # for NGX_LD_OPT
        --with-ld-opt="'$LDFLAGS'"
    )

    # Fix configure for musl-gcc
    export CC_AUX_FLAGS="$CFLAGS $LDFLAGS"
    # configure all unknown toolchain as gcc
    sed -i '/gcc)/i unknown) . auto/cc/gcc;;' auto/cc/conf

    if is_mingw; then
        sed -i auto/feature \
            -e 's/-x \$NGX_AUTOTEST/&.exe/g' \
            -e 's/-c \$NGX_AUTOTEST/&.exe/g' \
            || die "hack mingw exe failed."

        sed -e 's/win32/xxx/' \
            -i auto/lib/openssl/conf \
            -i auto/lib/pcre/conf \
            -i auto/lib/zlib/conf \
            || die "hack for mingw failed."
    fi


    configure

    make

    cmdlet ./objs/nginx

    check nginx -version

    caveats << EOF
static built nginx @ $libs_ver with fancyindex

defaults:
  config:   /etc/nginx/nginx.conf
  runtime:  /var/run/nginx.pid
            /var/run/nginx.lock
            /var/run/nginx/*
  logfile:  /var/log/nginx/access.log
            /var/log/nginx/error.log

EOF
}

libs.depends ! is_mingw

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
