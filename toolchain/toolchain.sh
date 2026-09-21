#!/bin/bash
#
# shellcheck disable=SC2086,SC2206

set -eo pipefail

# multicall name
NAME="$(basename "$0")"

# target env
: "${_TARGET:=$(uname -m)-linux-gnu}"
: "${_ZIG_TARGET:=}"    # experimental, keep it empty by default

# extra envs
: "${PREFIX:=prebuilts/$_TARGET}"
: "${_WORKDIR:="${_TARGET_WORKDIR:-$_TARGET}"}"
: "${_LOGFILE:=toolchain.log}"

die() {
    echo "❌ $*"
    exit 1
}

logcmd() {
    {
        printf '☘️ '
        printf '%s ' "$@"
        printf '\n'
    } >> "$_LOGFILE"

    "$@"
}

# pipe stderr
exec 3>&2
exec 2> >(tee -a "$_LOGFILE" >&3)

# special case
case "$NAME" in
    pkg-config)
        : "${PKG_CONFIG:=$(command -v $_TARGET-pkg-config)}"
        : "${PKG_CONFIG:=$(command -v pkg-config)}"
        : "${PKG_CONFIG_PATH:=$PREFIX/lib/pkgconfig}"
        : "${PKG_CONFIG_LIBDIR:=$PREFIX/lib}"

        export PKG_CONFIG_PATH PKG_CONFIG_LIBDIR

        # append result to _LOGFILE as pkg-config usually runs inside $()
        # must set -o pipefail
        logcmd pkg-config --define-variable=PREFIX="$PREFIX" --static "$@" | tee -a "$_LOGFILE"
        exit
        ;;
    hostcc)
        unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
        logcmd cc "$@"
        exit
        ;;
esac

if test -n "$_ZIG_TARGET"; then
    # reset envs
    #  https://wiki.gentoo.org/wiki/Zig#Environment_variables
    unset ZIG_TARGET ZIG_CPU ZBS_ARGS_EXTRA

    # set zig target
    case "$_ZIG_TARGET" in
        *-linux-gnu)
            # default glibc 2.31 (ubuntu 20.04, Debian 11, ...)
            #  compatible + modern c++ and posix features
            _ZIG_TARGET="$_ZIG_TARGET.2.31"
            ;;
    esac

    unset cpp
    for x in "$@"; do
        case "$x" in
            -E | --help | -help | -print-* | -dump* | --version)
                cpp=true
                ;;
            -v)
                # special command: gcc -v
                [ $# -gt 1 ] || cpp=true
                ;;
            -o)
                has_target=true
                ;;
            *.o | *.a)
                has_object_files=true
                ;;
            *.c | *.cc | *.cpp)
                has_source_files=true
                ;;
        esac
    done

    # zig: error: version '.2.31' in target triple 'x86_64-unknown-linux-gnu.2.31' is invalid
    # fix: remove glibc version from target
    #  https://codeberg.org/ziglang/zig/issues/30178
    test -z "$cpp" || _ZIG_TARGET="${_ZIG_TARGET%%.2.*}"

    # force use system linker
    #export ZIG_SYSTEM_LINKER_HACK=1

    unset flags
    #test -n "$cpp" || flags+=(-flto) #=> ld.lld: warning: ./libreadline.a: archive member 'readline.o' is neither ET_REL nor LLVM bitcode

    case "$NAME" in
        gcc | cc | as | ld)
            EXE=(zig cc -target $_ZIG_TARGET "${flags[@]}")
            ;;

        g++ | c++)
            EXE=(zig c++ -target $_ZIG_TARGET "${flags[@]}")
            ;;

        # no zig strip
        strip | nm)
            unset EXE
            # zig use llvm clang, so prefer llvm tools
            : "${EXE:=$(command -v llvm-$NAME)}"
            : "${EXE:=$(command -v $_TARGET-$NAME)}"
            : "${EXE:=$(command -v $NAME)}"
            ;;

        # windows
        windres | rc)
            EXE=(zig rc)
            ;;

        *)
            EXE=(zig $NAME) # no -target
            ;;
    esac
else
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
fi

: "${EXE:=$NAME}"

logcmd "${EXE[@]}" "$@"
