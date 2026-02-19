#!/usr/bin/env bash

set -eo pipefail

: "${PREFIX:=prebuilts/$(uname -m)-apple-darwin}"

# pkg-config variables
: "${REAL_PKG_CONFIG:=pkg-config}"
: "${PKG_CONFIG_LIBDIR:=$PREFIX/lib}"
: "${PKG_CONFIG_PATH:=$PREFIX/lib/pkgconfig}"

# xorg installed pkgconfig into share instead of lib
#test -d "$PREFIX/share/pkgconfig" && PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$PREFIX/share/pkgconfig"

export PKG_CONFIG_LIBDIR PKG_CONFIG_PATH

: "${PRINTF:=$(which printf)}"
: "${_LOGFILE:=pkg-config.log}"
{
    "$PRINTF" '\n'
    "$PRINTF" 'pkg_config.sh: %s ' "$REAL_PKG_CONFIG"
    "$PRINTF" '%q ' "$@"
    "$PRINTF" '\n'
} >> "$_LOGFILE"

# log both stdout and stderr
"$REAL_PKG_CONFIG" --define-variable=PREFIX="$PREFIX" --static "$@" \
    1> >( tee -a "$_LOGFILE" ) \
    2> >( tee -a "$_LOGFILE" >&2 )

wait
