#!/bin/bash

set -eo pipefail

# multicall name
NAME="${0##*/}"

# defaults
: "${PREFIX:=prebuilt/$(uname -m)-linux-gnu}"
: "${_TARGET:=}" # no default
: "${_LOGFILE:=toolchain.log}"
: "${_TARGET_PKG_CONFIG:=pkg-config}"

# pipe stderr
exec 3>&2
exec 2> >(tee -a "$_LOGFILE" >&3)

PRESET="${0%/*}/presets/${_TARGET:-default}.txt"

# toolchain: gcc, g++, nm, ld, ...
if ! test -f "$PRESET"; then
    TOOLS=(gcc g++ ld ar as nm objcopy objdump ranlib strip readelf)

    # set toolchain prefix
    case "$_TARGET" in
        *-linux-gnu)    TOOLCHAIN="$(uname -m)-linux-musl"      ;;
        *-w64-mingw32)  TOOLCHAIN="$(uname -m)-w64-mingw32"     ;;
    esac

    case "$_TARGET" in
        *-w64-*) TOOLS+=(dlltool windres) ;;
    esac

    mkdir -p "${PRESET%/*}"
    if which xcrun > /dev/null 2>&1; then
        for tool in "${TOOLS[@]}"; do
            echo "${tool//+/x}='$(xcrun --find "$tool")'"
        done
    elif test -z "$TOOLCHAIN"; then
        for tool in "${TOOLS[@]}"; do
            echo "${tool//+/x}='$(which "$tool")'"
        done
    else
        for tool in "${TOOLS[@]}"; do
            echo "${tool//+/x}='$TOOLCHAIN-$tool'"
        done
    fi > "$PRESET"
fi

# load toolchain file
. "$PRESET"

{
    printf '\n'
    printf '☘️ %s ' "$NAME"
    printf '%q ' "$@"
    printf '\n'
} >> "$_LOGFILE"

case "$NAME" in
    pkg-config)
        : "${PKG_CONFIG_PATH:=$PREFIX/lib/pkgconfig}"
        : "${PKG_CONFIG_LIBDIR:=$PREFIX/lib}"

        export PKG_CONFIG_PATH PKG_CONFIG_LIBDIR

        # must set -o pipefail
        "$_TARGET_PKG_CONFIG" --define-variable=PREFIX="$PREFIX" --static "$@" | tee -a "$_LOGFILE"

        exit
        ;;
esac

# find out the real executable
EXE="$(eval "echo \${${NAME//+/x}}")"

exec "$EXE" "$@"
