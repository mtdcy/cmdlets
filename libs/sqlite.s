# Command-line interface for SQLite

# shellcheck disable=SC2034
libs_lic='blessing'
libs_ver=3.50.4
libs_url=https://github.com/sqlite/sqlite/archive/refs/tags/version-$libs_ver.tar.gz
libs_sha=74ed9d2e5930d79564d92b838a61f943a9df01403b51f479fb64ce9aa5dca70d
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
        --disable-rpath

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
