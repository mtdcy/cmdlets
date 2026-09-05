#!/bin/bash

set -eo pipefail

# multicall name
NAME="${0##*/}"

# defaults
: "${PREFIX:=prebuilt/$(uname -m)-linux-gnu}"
: "${_TARGET:=$CMDLET_TARGET}"
: "${_TARGET_WORKDIR:=out/$_TARGET}"
: "${_LOGFILE:=toolchain.log}"

die() {
    echo "❌ $*"
    exit 1
}

# pipe stderr
exec 3>&2
exec 2> >(tee -a "$_LOGFILE" >&3)

CONFIG="$_TARGET_WORKDIR/$_TARGET.cfg"

# toolchain: gcc, g++, nm, ld, ...
if ! test -f "$CONFIG"; then
    TOOLS=(gcc g++ ld ar as nm objcopy objdump ranlib strip)

    case "$_TARGET" in
        *-windows* | *-mingw* | *-cygwin*)
            TOOLS+=(dlltool windres)
            TOOLCHAIN="$_TARGET"
            ;;
        *-darwin*)
            TOOLS+=(otool)
            ;;
        *)
            TOOLS+=(readelf)

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

# find out the real executable
EXE="$(eval "echo \${${NAME//+/x}}")"

test -n "$EXE" || EXE="$(which "$NAME")" || die "no $NAME found"

{
    printf '☘️ %s ' "${EXE:-$NAME}"
    printf '%q ' "$@"
    printf '\n\n'
} >> "$_LOGFILE"

case "$NAME" in
    pkg-config)
        : "${PKG_CONFIG_PATH:=$PREFIX/lib/pkgconfig}"
        : "${PKG_CONFIG_LIBDIR:=$PREFIX/lib}"

        # pkg-config from toolchain or host
        test -n "$toolchain" && EXE="$toolchain-pkg-config" || EXE=pkg-config

        # fallback to host pkg-config
        which "$EXE" &> /dev/null || EXE="$(which pkg-config)"

        export PKG_CONFIG_PATH PKG_CONFIG_LIBDIR

        # append result to _LOGFILE as pkg-config usually runs inside $()
        # must set -o pipefail
        "$EXE" --define-variable=PREFIX="$PREFIX" --static "$@" | tee -a "$_LOGFILE"

        exit
        ;;
    *)
        exec "$EXE" "$@"
        ;;
esac
