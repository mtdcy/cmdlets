#!/usr/bin/env bash

set -eo pipefail

: "${REAL_CXX:=g++}"

: "${CCACHE_DISABLE:=0}"
: "${CCACHE_DIR:=.ccache}"

# log command only
: "${PRINTF:=$(which printf)}"
: "${_LOGFILE:=g++.log}"
{
    "$PRINTF" '\n'
    "$PRINTF" 'g++.sh: %s ' "$REAL_CXX"
    "$PRINTF" '%q ' "$@"
    "$PRINTF" '\n'
} >> "$_LOGFILE"

# keep stdout and stderr as it is
if [ "$CCACHE_DISABLE" -ne 0 ]; then
    "$REAL_CXX" "$@"
else
    ccache "$REAL_CXX" "$@"
fi
