#!/usr/bin/env bash

set -eo pipefail

: "${REAL_CC:=gcc}"

: "${CCACHE_DISABLE:=0}"
: "${CCACHE_DIR:=.ccache}"

# log command only
: "${PRINTF:=$(which printf)}"
: "${_LOGFILE:=gcc.log}"
{
    "$PRINTF" '\n'
    "$PRINTF" 'gcc.sh: %s ' "$REAL_CC"
    "$PRINTF" '%q ' "$@"
    "$PRINTF" '\n'
} >> "$_LOGFILE"

# keep stdout and stderr as it is
if [ "$CCACHE_DISABLE" -ne 0 ]; then
    "$REAL_CC" "$@"
else
    ccache "$REAL_CC" "$@"
fi
