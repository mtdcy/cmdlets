# Postgres C API library
# https://www.postgresql.org/docs/current/libpq.html
#
# shellcheck disable=SC2034
libs_lic='PostgreSQL'
libs_ver=18.0
libs_url=https://github.com/postgres/postgres/archive/refs/tags/REL_18_0.tar.gz
libs_sha=d9071ab45c2c45a3c8371495539ea7d2ed4d8035f72de20cb7cddfe23081cb82
libs_dep=( zlib libxslt openssl krb5 )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --sysconfdir=/etc # for krb5.keytab

    --with-gssapi   # krb5
    --with-openssl

    --without-icu
    --disable-debug

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    deparallelize

    # fix static krb5
    export LIBS="$($PKG_CONFIG --libs-only-l krb5-gssapi)"

    # FIXME: krb5support been filter out somewhere
    #export LDFLAGS+=" -lkrb5support"

    configure

    # only static libraries
    find src -name "Makefile*" -exec sed -i \
        -e 's/ all-shared-lib//g'           \
        -e 's/ install-lib-shared//g'       \
        {} +

    sed -i src/interfaces/libpq/Makefile    \
        -e 's/ libpq-refs-stamp//g'

    # https://stackoverflow.com/questions/68379786/building-postgres-from-source-throws-utils-errcodes-h-file-not-found-when-ca
    # MAKELEVEL: fatal error: 'utils/errcodes.h' file not found
    make -C src/common MAKELEVEL=0
    make -C src/port MAKELEVEL=0
    make -C src/interfaces MAKELEVEL=0

    # fix pkgconfig files, refer to src/common/Makefile
    find src/interfaces -name "*.pc" -exec sed -i \
        -e 's/-lpgcommon /-lpgcommon_shlib /g' \
        {} +

    make -C src/include install
    make -C src/interfaces install
    make -C src/common install
    make -C src/port install

    # fix installed pkgconfig files
    LIBS="$($PKG_CONFIG --libs libpq krb5-gssapi | sed 's/^.*-lpq //')"

    sed -i "$PREFIX/lib/pkgconfig/libpq.pc" \
        -e "s%^Libs.private:.*%Libs.private: $LIBS%"

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
