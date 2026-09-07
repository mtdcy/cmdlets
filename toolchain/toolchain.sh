#!/bin/bash

set -eo pipefail

# multicall name
NAME="$(basename "$0")"

# target env
: "${_TARGET:=$(uname -m)-linux-gnu}"

# extra envs
: "${PREFIX:=prebuilts/$_TARGET}"
: "${_WORKDIR:="${_TARGET_WORKDIR:-out/$_TARGET}"}"
: "${_LOGFILE:=$_WORKDIR/toolchain.log}"

die() {
    echo "❌ $*"
    exit 1
}

# pipe stderr
exec 3>&2
exec 2> >(tee -a "$_LOGFILE" >&3)

CONFIG="$_WORKDIR/$_TARGET.cfg"

# toolchain: gcc, g++, nm, ld, ...
if ! test -f "$CONFIG"; then
    TOOLS=(gcc g++ ld ar as nm objdump ranlib strip)

    case "$_TARGET" in
        *-windows* | *-mingw* | *-cygwin*)
            TOOLS+=(objcopy dlltool windres)
            TOOLCHAIN="$_TARGET"
            ;;
        *-darwin*)
            TOOLS+=(otool)
            ;;
        *)
            TOOLS+=(objcopy readelf)

            # prefer musl-gcc > gnu-gcc
            TOOLCHAIN="$(uname -m)-linux-musl"
            which "$TOOLCHAIN-gcc" > /dev/null 2>&1 || TOOLCHAIN="$_TARGET"
            ;;
    esac

    mkdir -p "${CONFIG%/*}"
    if which xcrun > /dev/null 2>&1; then
        for tool in "${TOOLS[@]}"; do
            echo "${tool//+/x}='$(xcrun --find "$tool")'"
        done
    elif test -z "$TOOLCHAIN"; then
        for tool in "${TOOLS[@]}"; do
            echo "${tool//+/x}='$(which "$tool")'"
        done
    else
        echo "toolchain=$TOOLCHAIN"
        for tool in "${TOOLS[@]}"; do
            echo "${tool//+/x}='$TOOLCHAIN-$tool'"
        done
    fi > "$CONFIG"
fi

# load toolchain file
. "$CONFIG"

# escaped name
ESCAPED="$(sed -e 's/+/x/g' -e 's/-/_/g' -e 's/ /_/g' <<< "$NAME")"

# find out the real executable
EXE="${!ESCAPED}"

: "${EXE:=$NAME}"
{
    printf '☘️ %s ' "$EXE"
    printf '%q ' "$@"
    printf '\n'
} >> "$_LOGFILE"

case "$NAME" in
    pkg-config)
        : "${PKG_CONFIG_PATH:=$PREFIX/lib/pkgconfig}"
        : "${PKG_CONFIG_LIBDIR:=$PREFIX/lib}"

        export PKG_CONFIG_PATH PKG_CONFIG_LIBDIR

        # append result to _LOGFILE as pkg-config usually runs inside $()
        # must set -o pipefail
        "$EXE" --define-variable=PREFIX="$PREFIX" --static "$@" | tee -a "$_LOGFILE"
        ;;
    *)
        exec "$EXE" "$@"
        ;;
esac
