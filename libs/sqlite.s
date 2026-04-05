# Command-line interface for SQLite

# shellcheck disable=SC2034
libs_lic='blessing'
libs_ver=3.52.0
libs_url=https://github.com/sqlite/sqlite/archive/refs/tags/version-$libs_ver.tar.gz
libs_sha=52218646a6ce3f9c866c0592ea3b9f6f25c56b24b529605c95de2d50739de5c3
libs_dep=( zlib readline )

libs_build() {
    libs_args=(
        --disable-option-checking
        --enable-silent-rules
        --disable-dependency-tracking

        --all
        --enable-readline
        --disable-editline
        --enable-session
        --with-readline-cflags="'$($PKG_CONFIG --cflags readline)'"
        --with-readline-ldflags="'$($PKG_CONFIG --libs readline)'"
    
        --disable-nls

        # static
        --disable-shared
        --enable-static
    )

    # Default value of MAX_VARIABLE_NUMBER is 999 which is too low for many
    # applications. Set to 250000 (Same value used in Debian and Ubuntu).
    defines=(
        -DSQLITE_ENABLE_API_ARMOR=1
        -DSQLITE_ENABLE_COLUMN_METADATA=1
        -DSQLITE_ENABLE_DBSTAT_VTAB=1
        -DSQLITE_ENABLE_FTS3=1
        -DSQLITE_ENABLE_FTS3_PARENTHESIS=1
        -DSQLITE_ENABLE_FTS5=1
        -DSQLITE_ENABLE_GEOPOLY=1
        -DSQLITE_ENABLE_JSON1=1
        -DSQLITE_ENABLE_MEMORY_MANAGEMENT=1
        -DSQLITE_ENABLE_RTREE=1
        -DSQLITE_ENABLE_STAT4=1
        -DSQLITE_ENABLE_UNLOCK_NOTIFY=1
        -DSQLITE_MAX_VARIABLE_NUMBER=250000
        -DSQLITE_USE_URI=1
    )
    export CPPFLAGS="$CPPFLAGS ${defines[*]}"

    configure && make || return 1

    pkgfile libsqlite -- make install-lib install-headers install-pc

    cmdlet ./sqlite3 && 

    check sqlite3 --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
