# Postgres C API library
# https://www.postgresql.org/docs/current/libpq.html
#
# shellcheck disable=SC2034
libs_lic='PostgreSQL'
libs_ver=18.0
libs_url=https://github.com/postgres/postgres/archive/refs/tags/REL_18_0.tar.gz
libs_sha=d9071ab45c2c45a3c8371495539ea7d2ed4d8035f72de20cb7cddfe23081cb82
libs_dep=( zlib zstd libxslt openssl krb5 )

libs_args=(
    -Dprefer_static=true
    -Db_staticpic=true
    -Db_pie=true

    -Dlz4=enabled
    -Dzlib=enabled
    -Dzstd=enabled
    -Dlibedit_preferred=true
    -Dlibxml=enabled
    -Dlibxslt=enabled
    -Dreadline=enabled
    -Dgssapi=enabled
    -Dssl=openssl

    #-Duuid=e2fs

    -Dicu=disabled
    -Dnls=disabled

    -Dplperl=disabled
    -Dplpython=disabled
    -Dpltcl=disabled

    -Ddocs=disabled
    #-Ddocs_pdf=disabled

    -Dbonjour=disabled
    -Dbsd_auth=disabled
    -Dbonjour=disabled
    -Dldap=disabled
    -Dpam=disabled
    -Dbonjour=disabled
    -Dsystemd=disabled
)

libs_build() {
    deparallelize

    # fix static krb5
    #export LIBS="$($PKG_CONFIG --libs krb5)"

    # for dns_open & dns_close => FIXME: fix this in krb5
    #is_darwin && LIBS+=" -lresolv"

    meson setup build

    meson compile -C build --verbose

    pkgfile libpq -- meson install -C build

    # https://stackoverflow.com/questions/68379786/building-postgres-from-source-throws-utils-errcodes-h-file-not-found-when-ca
    # MAKELEVEL: fatal error: 'utils/errcodes.h' file not found
    #make -C src/interfaces/libpq MAKELEVEL=0

#   # install only static client libraries
#   for x in src/include src/interfaces src/common src/port; do
#       make -C "$x" install \
#           libdir="'$PREFIX/lib'" \
#           includedir="'$PREFIX/include'" \
#           pkgincludedir="'$PREFIX/include/postgresql'" \
#           includedir_server="'$PREFIX/include/postgresql/server'" \
#           includedir_internal="'$PREFIX/include/postgresql/internal'"
#   done
#   pkgfile libpq -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
