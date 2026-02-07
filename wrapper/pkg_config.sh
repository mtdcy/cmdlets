#!/usr/bin/env bash

set -eo pipefail

: "${PREFIX:=prebuilts/$(uname -m)-apple-darwin}"
: "${PKG_CONFIG_LIBDIR:=$PREFIX/lib}"
: "${PKG_CONFIG_PATH:=$PREFIX/lib/pkgconfig}"
: "${REAL_PKG_CONFIG:=$(which pkg-config)}"
: "${_LOGFILE:=pkg-config.log}"

# xorg installed pkgconfig into share instead of lib
#test -d "$PREFIX/share/pkgconfig" && PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$PREFIX/share/pkgconfig"

export PKG_CONFIG_LIBDIR PKG_CONFIG_PATH

{
    printf '%s ' "$0"
    printf '%q ' "$@"
    printf '\n'
} >> "$_LOGFILE"

"$REAL_PKG_CONFIG" --define-variable=PREFIX="$PREFIX" --static "$@" \
    1> >( tee -a "$_LOGFILE" ) \
    2> >( tee -a "$_LOGFILE" >&2 )
