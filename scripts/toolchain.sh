#!/usr/bin/env bash

set -eo pipefail

# multicall name
NAME="$(basename "$0")"

eval -- REAL_EXE=\"\${REAL_$NAME:-$NAME}\"

# prefix
: "${PREFIX:=prebuilts/$(uname -m)-linux-gnu}"

# log command
: "${PRINTF:=$(which printf)}"
: "${_LOGFILE:=toolchain.log}"
{
    "$PRINTF" '\n'
    "$PRINTF" '#: %s ' "$REAL_EXE"
    "$PRINTF" '%q ' "$@"
    "$PRINTF" '\n'
} >> "$_LOGFILE"

# keep stdout and stderr as it is
case "$NAME" in
    cc|cxx)
        "$REAL_EXE" "$@"
        ;;
    pkg_config)
        # pkg-config variables
        : "${PKG_CONFIG_LIBDIR:=$PREFIX/lib}"
        : "${PKG_CONFIG_PATH:=$PREFIX/lib/pkgconfig}"

        export PKG_CONFIG_LIBDIR PKG_CONFIG_PATH

        "$REAL_EXE" --define-variable=PREFIX="$PREFIX" --static "$@" | tee -a "$_LOGFILE"
        ;;
    *)
        "$REAL_EXE" "$@"
        ;;
esac 2> >( tee -a "$_LOGFILE" >&2 )
