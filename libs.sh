#!/bin/bash

# shellcheck shell=bash
# shellcheck disable=SC2018
# shellcheck disable=SC2019
# shellcheck disable=SC2031
# shellcheck disable=SC2086
# shellcheck disable=SC2115
# shellcheck disable=SC2154

set -e -o pipefail

umask  0022
export LANG=C

# public options      =
        CMDLET_LOGGING=${CMDLET_LOGGING:-tty}       # tty,plain,silent
        CMDLET_MIRRORS=${CMDLET_MIRRORS:-}          # package mirrors, and go/cargo/etc
         CMDLET_CCACHE=${CMDLET_CCACHE:-0}          # enable ccache or not
           CMDLET_REPO=${CMDLET_REPO:-}             # cmdlet pkgfiles repo
         CMDLET_TARGET=${CMDLET_TARGET:-}

# public build options  =
      CMDLET_BUILD_NJOBS=${CMDLET_BUILD_NJOBS:-1}   # no parallel build by default
      CMDLET_NO_PKGFILES=${CMDLET_NO_PKGFILES:-0}   # force build dependencies

# toolchain prefix

# set private vairables
_LOGGING="${CMDLET_LOGGING:-plain}"

if [ "$_LOGGING" = "tty" ]; then
    test -t 1 && which tput &>/dev/null || _LOGGING=plain
fi

# target, default: musl-gcc
_TARGET="${CMDLET_TARGET:-$(uname -m)-$(uname -s | tr A-Z a-z)-musl}"

which "$_TARGET-gcc" &>/dev/null || unset _TARGET

# pkgfiles repo
_REPO="${CMDLET_REPO:-https://pub.mtdcy.top/cmdlets/latest}"

# mirrors
_MIRRORS="${CMDLET_MIRRORS:-https://mirrors.mtdcy.top}"

curl -fsIL --connect-timeout 1 "$_MIRRORS" -o /dev/null || unset _MIRRORS

if test -n "$_MIRRORS"; then
    : "${_CARGO_REGISTRY:=$_MIRRORS/crates.io-index/}"
    : "${_GO_PROXY:=$_MIRRORS/gomods}"
fi

# build args
_NJOBS="${CMDLET_BUILD_NJOBS:-1}"

# clear envs => setup by _init
unset _ROOT _WORKDIR PREFIX
# => PREFIX is a widely used variable

# defaults
: "${MACOSX_DEPLOYMENT_TARGET:=11.0}"
# check: otool -l <path_to_binary> | grep minos

# help functions
is_listed()         { [[ " ${*:2} " == *" $1 "* ]];     }   # is $1 in list ${@:2}?
is_match()          { [[ " ${*:2} " =~ " "$1" " ]];     }   # is $1 in list ${@:2}?

# target check: ready after _init, at least CC is set.
is_msys()           { [[ "$OSTYPE" =~ msys ]] || test -n "$MSYSTEM";    } # deprecated
is_clang()          { is_listed clang           "${_TARGETVARS[@]}";    }
is_darwin()         { is_listed apple           "${_TARGETVARS[@]}";    }
is_linux()          { is_listed linux           "${_TARGETVARS[@]}";    }
is_glibc()          { is_listed gnu             "${_TARGETVARS[@]}";    }
is_musl()           { is_listed musl            "${_TARGETVARS[@]}";    }
is_win64()          { is_listed w64             "${_TARGETVARS[@]}";    }
is_mingw()          { is_listed mingw32         "${_TARGETVARS[@]}";    }
is_arm64()          { is_match  "arm64|aarch64" "${_TARGETVARS[@]}";    }
is_intel()          { is_match  "x86_64|x86"    "${_TARGETVARS[@]}";    }
is_posix()          { is_listed posix           "${_TARGETVARS[@]}";    }

host.is_glibc()     { is_listed GLIBC           "${_HOSTVARS[@]}";      }
host.is_linux()     { is_listed linux           "${_HOSTVARS[@]}";      }
host.is_darwin()    { is_match  "darwin*"       "${_HOSTVARS[@]}";      }

# slog [error|info|warn] "leading" "message"
_slog() {
    local ret=$?
    local lvl date message

    [ $# -gt 1 ] && lvl="$1" && shift 1
    date="$(date '+%m-%d %H:%M:%S')"

    # https://github.com/yonchu/shell-color-pallet/blob/master/color16
    case "$(tr '[:upper:]' '[:lower:]' <<< "$lvl")" in
        error)
            message="[$date] \\033[31m$1\\033[39m ${*:2}"
            ;;
        warn)
            message="[$date] \\033[33m$1\\033[39m ${*:2}"
            ;;
        info|*)
            message="[$date] \\033[32m$1\\033[39m ${*:2}"
            ;;
    esac
    echo -e "$message" >&2
    return $ret
}

slogi() { _slog info  "$@";             }
slogw() { _slog warn  "$@";             }
sloge() { _slog error "$@"; return 1;   }

die()   {
    _tty_reset # in case Ctrl-C happens
    test -z "$*" || _slog error "....." "$@"
    exit 1 # exit shell
}

_capture() {
    test -n "$_LOGFILE" || return 0
    case "$_LOGGING" in
        silent)
            cat >> "$_LOGFILE"
            ;;
        tty)
            local i=0
            tput dim                        # dim on
            tput rmam                       # line break off
            while read -r line; do
                i=$((i+1))

                tput ed                     # clear to end of screen
                tput sc                     # save cursor position
                printf "#$i: %s" "$line"
                tput rc                     # restore cursor position
            done < <(tee -a "$_LOGFILE")
            _tty_reset
            ;;
        *)
            tee -a "$_LOGFILE"
            ;;
    esac
}

_tty_reset() {
    [ "$_LOGGING" = "tty" ] || return 0

    tput ed         # clear to end of screen
    tput smam       # line break on
    tput sgr0       # reset colors
}

_capture_stderr() {
    test -n "$_LOGFILE" || return 0
    case "$_LOGGING" in
        plain)  tee -a "$_LOGFILE" ;;
        *)      cat >> "$_LOGFILE" ;;
    esac >&2
}

# why eval as string?
#  Pros:
#   slogcmd "$PATCH -p1 -N < $file"     # redirect evals well
#   pkgfile git bin/git bin/git-*       # glob works fine
#
#  Cons:
#   --prefix="'$PREFIX'"                # must be quoted twice
echocmd() {
    # stderr: grep won't filter out the command
    echo "$@" | _LOGGING="${_LOGGING:-silent}" _capture_stderr

    # capture both stdout and stderr
    #  => logging as plain by default so grep will works
    eval -- "$*" 2>&1 | _LOGGING=${_LOGGING:-plain} _capture
}

# slogcmd <command>
slogcmd() {
    slogi "..Run" "$@" >&2

    _LOGGING="${_LOGGING:-silent}" echocmd "$@"
}

_init() {
    test -z "$_ROOT" || return 0

    _ROOT="$(pwd -P)"

    if test -n "$_TARGET"; then
        _ARCH="$_TARGET"
    elif [ "$(uname -s)" = Darwin ]; then
        _ARCH="$(uname -m)-apple-darwin"
    else
        _ARCH="$(uname -m)-$OSTYPE"
    fi

    # compatible
    [[ "$_ARCH" =~ -musl$ ]] && _ARCH="${_ARCH/%-musl/-gnu}"

    # prepare variables
    PREFIX="$_ROOT/prebuilts/$_ARCH"

    # private variables
    _WORKDIR="$_ROOT/out/$_ARCH"
    _PACKAGES="$_ROOT/packages"
    _LOGFILES="$_ROOT/logs/$_ARCH"
    _MANIFEST="$PREFIX/cmdlets.manifest"

    mkdir -p "$PREFIX" "$_WORKDIR" "$_PACKAGES" "$_LOGFILES"
    mkdir -p "$PREFIX"/{bin,include,lib{,/pkgconfig}}

    true > "$PREFIX/.ERR_MSG" # create a zero sized file

    export PREFIX _ROOT _WORKDIR _PACKAGES _LOGFILES _MANIFEST

    # find out CC
    test -n "$_TARGET" && CC="$_TARGET-gcc" || CC=gcc

    which xcrun &>/dev/null && CC="$(xcrun --find "$CC")" || CC="$(which "$CC")"

    test -n "$CC" && test -x "$CC" || die "missing gcc"

    # toolchain utils
    export CC
    export AR="${CC/%gcc/ar}"
    export AS="${CC/%gcc/as}"
    export LD="${CC/%gcc/ld}"
    export NM="${CC/%gcc/nm}"
    export CXX="${CC/%gcc/g++}"
    export STRIP="${CC/%gcc/strip}"
    export RANLIB="${CC/%gcc/ranlib}"
    export PKG_CONFIG="${CC/%gcc/pkg-config}"

    # Windows resource compiler
    export WINDRES="${CC/%gcc/windres}"

    # force posix compatible, e.g: libwinpthread
    test -x "$CC-posix"  && export CC="$CC-posix"   || true
    test -x "$CXX-posix" && export CXX="$CXX-posix" || true

    # for target checks
    IFS=' :-()' read -r -a _TARGETVARS < <({
        "$CC" -v 2>&1 | grep -E "Target:|Thread model:" | cut -d':' -f2
    } | xargs)
    IFS=' ' read -r -a _TARGETVARS < <( printf '%s\n' "${_TARGETVARS[@]}" | sort -u | xargs)

    # for host checks (not --host for configure)
    IFS=' :-()' read -r -a _HOSTVARS < <({
        echo "$OSTYPE"
        which gcc &>/dev/null && gcc --version | head -n1  # gcc version
        which ldd &>/dev/null && ldd --version 2>&1 | head -n1  # libc type
    } | xargs)
    IFS=' ' read -r -a _HOSTVARS < <( printf '%s\n' "${_HOSTVARS[@]}" | sort -u | xargs)

    # STRIP
    #  libraries: strip local symbols but keep debug
    #  binaries: strip all and debug symbols
    if "$STRIP" --version 2>/dev/null | grep -qFw Binutils; then
        export BIN_STRIP="$STRIP --strip-all"
    else
        export BIN_STRIP="$STRIP"
    fi

    local host_tools=(
        "MAKE:gmake,make"
        "CMAKE:cmake"
        "MESON:meson"
        "NINJA:ninja"
        "PATCH:patch"
        "INSTALL:install"
        "TAR:gtar,tar"
    )

    test -x "$PKG_CONFIG" || host_tools+=( PKG_CONFIG:pkg-config )

    is_arm64 || host_tools+=(
        NASM:nasm
        YASM:yasm
    )

    _init_host_tools() {
        local k v x p
        for x in "$@"; do
            IFS=':' read -r k v <<< "$x"

            for x in ${v//,/ }; do
                p="$(which "$x" 2>/dev/null)" && break
            done

            test -n "$p" && export "$k=$p" || slogw ".Init" "missing host tool $v"
        done
    }

    _init_host_tools "${host_tools[@]}"

    local cflags ldflags

    # common flags for c/c++
    cflags=(
        -g0 -Os             # optimize for size
        -fPIC -DPIC         # PIC
        -Wno-error          # no warnings as errors
    )
    ldflags=(
        -L$PREFIX/lib       # prebuilts
    )

    # macOS does not support statically linked binaries
    if is_darwin; then
        cflags+=(
            -Wno-deprecated-non-prototype
            -mmacosx-version-min="$MACOSX_DEPLOYMENT_TARGET"
        )
        ldflags+=( -Wl,-dead_strip )
    elif is_mingw; then
        # mingw windows headers
        #echo "#include <windows.h>" > "$TEMPDIR/test.c"
        #local inc="$( "$CC" -v -H "$TEMPDIR/test.c" 2>&1 | grep -oE "/.*/windows.h" -m1 | xargs dirname )"
        #cflags+=( -I"$inc" )

        # wine windows headers and libraries
        #cflags+=( -I/usr/include/wine/windows )
        #ldflags+=( -L/usr/lib/wine/$(uname -m)-windows )

        cflags+=( --static -ffunction-sections -fdata-sections )

        is_posix && cflags+=( -D_POSIX )

        # XXX: allow link with certain dlls?
        ldflags+=( -Wl,-gc-sections -Wl,--as-needed -static -static-libstdc++ -static-libgcc -Wl,-Bstatic )

        # ucrt: https://stackoverflow.com/questions/57528555/how-do-i-build-against-the-ucrt-with-mingw-w64 
        #"$CC" -dumpspecs > "$_WORKDIR/.specs"
        #sed -i 's/-lmsvcrt/-lucrt/g' "$_WORKDIR/.specs"
        #cflags+=( -specs="$_WORKDIR/.specs" -D_UCRT )
    else
        #1. static linking => two '--' vs ldflags
        #2. tell compiler to place each function and data into its own section
        cflags+=(
            --static
            -ffunction-sections
            -fdata-sections
        )

        # remove unused sections, need -ffunction-sections and -fdata-sections
        ldflags+=( -Wl,-gc-sections )

        # Security: FULL RELRO
        ldflags+=( -Wl,-z,relro,-z,now )

        # disable dynamic linking and link used symbols only
        ldflags+=( -Wl,--as-needed -static -static-libstdc++ -static-libgcc -Wl,-Bstatic )
    fi

    CFLAGS="${cflags[*]}"
    CXXFLAGS="${cflags[*]}"
    OBJCFLAGS="${cflags[*]}"
    OBJC="$CC"
    CPP="$CC -E"
    CPPFLAGS="-I$PREFIX/include"
    LDFLAGS="${ldflags[*]}"

    export CFLAGS OBJCFLAGS CXXFLAGS OBJC CPP CPPFLAGS LDFLAGS

    # command wrapper
    #  input: ENV wrapper.sh
    _command_wrapper() {
        eval export REAL_$1="\$$1"
        export $1="$_ROOT/scripts/$2"
    }

    # pkg-config: some build system do not support pkg-config with parameters
    _command_wrapper PKG_CONFIG pkg_config.sh
    # => PKG_CONFIG_PATH and PKG_CONFIG_LIBDIR are set in wrapper, but libraries like ncurses still need this
    PKG_CONFIG_LIBDIR="$PREFIX/lib"
    PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    export PKG_CONFIG_LIBDIR PKG_CONFIG_PATH

    # update PATH => tools like glib-compile-resources needs seat in PATH
    export PATH="$PREFIX/bin:$PATH"

    # for running test
    # LD_LIBRARY_PATH or rpath?
    #export LD_LIBRARY_PATH=$PREFIX/lib
    # rpath is meaningless for static libraries and executables, and
    # to avoid link shared libraries accidently, undefine LD_LIBRARY_PATH
    # will help find out the mistakes.

    # macos
    export MACOSX_DEPLOYMENT_TARGET
    # msys
    export MSYS=winsymlinks:lnk

    # win64 with wine
    if is_win64; then
        _BINEXT=".exe" || unset _BINEXT

        export WINE="$(which wine 2>/dev/null)" || true

        # enable binfmt support
        if test -n "$WINEPREFIX" && ! test -f /tmp/cmdlets_binfmt_ready; then
            # wine: '/wine' is not owned by you
            sudo chown "$(id -u):$(id -g)" "$WINEPREFIX"

            # enable binfmt support
            if ! test -e /proc/sys/fs/binfmt_misc; then
                sudo mount -t binfmt_misc none /proc/sys/fs/binfmt_misc
            fi

            if ! test -e /proc/sys/fs/binfmt_misc/wine; then
                sudo update-binfmts --import wine
                sudo update-binfmts --enable wine
            fi

            slogi "Wine binfmt status:"
            echo -e "binfmt: $(cat /proc/sys/fs/binfmt_misc/status)" >&2
            echo -e "wine: \n$(cat /proc/sys/fs/binfmt_misc/wine | sed 's/^/  /g')" >&2

            XDG_RUNTIME_DIR=/run/user/$(id -u)

            export XDG_RUNTIME_DIR
            touch /tmp/cmdlets_binfmt_ready
        fi
    fi
}

# _curl source destination [options]
_curl() {
    local source="$1"

    if test -n "$2"; then
        curl -fsI "${@:3}" "$source" -o /dev/null &&
        # show errors
        curl -fsSL "${@:3}" "$source" -o "$2"
    else
        # silent curl output for stdout
        curl -fsSL "${@:3}" "$source"
    fi
}

# fetch zip or die
#  input: zip sha url [mirrors ...]
_fetch() {
    local zip=$1
    local sha=$2
    local url=$3
    local _sha mirror

    mkdir -p "$(dirname "$zip")"

    #1. try local file first
    if [ -f "$zip" ]; then
        slogi ".FILE" "${zip#"$_ROOT/"}"

        # verify sha only if it exists
        test -n "$sha" || return 0

        IFS=' *' read -r _sha _ <<< "$(sha256sum "$zip")"
        if [ "$_sha" = "$sha" ]; then
            return 0
        else
            slogw "..SHA" "$_sha vs $sha (expected)"
            rm -f "$zip"
        fi
    fi

    #2. try mirror
    if test -n "$_MIRRORS"; then
        mirror="$_MIRRORS/packages/$libs_name/${zip##*/}"
        slogi ".CURL" "$mirror"
        _curl "$mirror" "$zip" || rm -f "$zip"
    fi

    #3. try originals
    if ! test -f "$zip"; then
        for url in "${@:3}"; do
            slogi ".CURL" "$url"
            _curl "$url" "$zip" && break || rm -f "$zip"
        done
    fi

    if test -f "$zip"; then
        slogi ".FILE" "$(sha256sum "$zip")"
    else
        sloge ".CURL" "fetch $3 failed." || die
    fi
}

# unzip file to current dir, or exit program
# _unzip <file> [strip]
_unzip() {
    slogi ".Zipx" "${1#"$_ROOT/"} => ${PWD#"$_ROOT/"}"

    [ -r "$1" ] || die "unzip $1 failed, permission denied?"

    # XXX: bsdtar --strip-components fails with some files like *.tar.xz
    #  ==> install gnu-tar with brew on macOS

    # match extensions
    case "$1" in
        *.tar)                  cmd=( "$TAR" -xv )          ;;
        *.tar.gz|*.tgz)         cmd=( "$TAR" -xv -z )       ;;
        *.tar.bz2|*.tbz2)       cmd=( "$TAR" -xv -j )       ;;
        *.tar.xz)               cmd=( "$TAR" -xv -J )       ;;
        *.tar.lz)               cmd=( "$TAR" -xv --lzip )   ;;
        *.tar.zst)              cmd=( "$TAR" -xv --zstd)    ;;
        *.rar)                  cmd=( unrar x )             ;;
        *.zip)                  cmd=( unzip -o )            ;;
        *.7z)                   cmd=( 7z x )                ;;
        *.gz)                   cmd=( gunzip )              ;;
        *.bz2)                  cmd=( bunzip )              ;;
        *.Z)                    cmd=( uncompress )          ;;
        *)                      false                       ;;
    esac

    case "${cmd[0]}" in
        "$TAR")
            # strip leading pathes
            # counting leading directories
            #local skip="${2:-$(tar -tf "$1" | grep -E '^[^/]+/?$' | head -n 1 | tr -cd "/" | wc -c)}"
            local skip="${2:-$("$TAR" -tf "$1" | grep -o '^[^/]*' | sort -u | wc -l)}"
            [ "$skip" -eq 1 ] || skip=0

            if "$TAR" --version | grep -qFw "bsdtar"; then
                cmd+=( --strip-components "$skip" )
            else
                cmd+=( --strip-components="$skip" )
            fi

            cmd+=( -f )
            ;;
    esac

    # silent this cmd to speed up build procedure
    _LOGGING=silent echocmd "${cmd[@]}" "$1" || die "unzip $1 failed."

    # post strip
    case "${cmd[0]}" in
        unzip)
            # if only one leading dir
            local leadings="${2:-$(unzip -l "$1" | awk '/\/$/ { print $NF }' | grep -o '^[^/]*' | sort -u)}"
            if [ "$(echo "$leadings" | wc -l)" -eq 1 ]; then
                # 'Directory not empty' reports if using mv
                cp -fr "$leadings"/* ./
                rm -fr "$leadings"/*
            fi
            ;;
    esac
}

# clone git repo
#  input: git_url#branch_or_tag_name [path]
_fetch_git() {
    local url branch
    local path="${2%.git*}"

    slogi "..GIT" "$1 => $path"

    IFS='#' read -r url branch <<< "$1"
    test -n "$branch" || branch="main"

    # reuse local repo
    if ! test -d "$path/.git"; then
        git clone --depth=1 --recurse-submodules --branch "$branch" --single-branch "$url" "$path" || die "git clone $1 failed."
    fi
}

_package_name() {
    local package
    # https://github.com/webmproject/libwebp/archive/refs/tags/v1.6.0.tar.gz
    if [[ "${1##*/}" =~ ^v?[0-9.]{2} ]]; then
        local path
        IFS=':/' read -r _ _ _ _ path <<< "$1"
        package="$_PACKAGES/$libs_name/${path//\//_}"
    else
        package="$_PACKAGES/$libs_name/${1##*/}"
    fi

    # https://github.com/ntop/ntopng/commit/a195be91f7685fcc627e9ec88031bcfa00993750.patch?full_index=1
    package="${package%\?*}"

    echo "$package"
}

# unzip url to workdir or die
#  input: sha url [mirrors...]
_fetch_unzip() {
    # e.g: libs_url="https://github.com/docker/cli.git#v$libs_ver"
    if [[ "${2%#*}" =~ \.git$ ]]; then
        _fetch_git "${@:2}" "${2##*/}"
    else
        # assemble zip name from url
        local zip="$(_package_name "$2")"

        # download zip file
        _fetch "$zip" "$1" "${@:2}"

        if file "$zip" | grep -Ewq "compressed|archive"; then
            # unzip to current fold
            _unzip "$zip" "${ZIP_SKIP:-}"
        else
            # copy ASCII text file directly
            cp -f "$zip" .
        fi
    fi
}

# _load library
_load() {
    . helpers.sh

    unset "${!libs_@}"

    slogi ".Load" "libs/$1.s"

    local file="libs/$1.s"
    local name="${1##*/}"

    # sed: delete all lines after __END__
    sed '/__END__/Q' "$file" > "$TEMPDIR/$name"

    . "$TEMPDIR/$name"

    # default values:
    test -n "$libs_name" || libs_name="$name"

    # update libs_dep to libs_deps, make old build compatible
    test -n "$libs_deps" || libs_deps=( "${libs_dep[@]}" )

    sed '1,/__END__/d' "$file" > "$TEMPDIR/$libs_name.patch"

    # prepare logfile
    mkdir -p "$_LOGFILES"
    export _LOGFILE="$_LOGFILES/$libs_name.log"
}

_prepare_workdir() {
    local workdir="$_WORKDIR/$libs_name-$libs_ver"

    mkdir -p "$PREFIX"
    mkdir -p "$workdir" && cd "$workdir" || die "prepare workdir failed."

    slogi ".WDIR" "${PWD#"$_ROOT/"}"
}

# prepare source code or die
_prepare() {
    _load "$1"

    if [ "$libs_type" = ".PHONY" ]; then
        slogw "<<<<<" "skip dummy target $libs_name"
        return 127
    fi

    test -n "$libs_url" || die "missing libs_url"

    # enter working directory
    _prepare_workdir

    # libs_url: support mirrors
    _fetch_unzip "$libs_sha" "${libs_url[@]}"

    local x patch

    # libs_resources: no mirrors
    if test -n "${libs_resources[*]}"; then
        local url sha
        for x in "${libs_resources[@]}"; do
            IFS=';|' read -r url sha <<< "$x"
            # never strip component of resources zip
            ZIP_SKIP=0 _fetch_unzip "$sha" "$url"
        done
    fi

    # libs_patches: web ready
    for patch in "${libs_patches[@]}"; do
        case "$patch" in
            http://*|https://*)
                local file="$(_package_name "$patch")"
                test -f "$file" || _curl "$patch" "$file"

                slogcmd "$PATCH" -Np1 -i "$file" ||
                slogcmd "$PATCH" -Np0 -i "$file" ||
                die "patch < $file failed."
                ;;
            *)
                slogcmd "$PATCH" -Np1 -i "$patch" ||
                slogcmd "$PATCH" -Np0 -i "$patch" ||
                die "patch < $patch failed."
                ;;
        esac
    done

    # always patch with -p1
    if test -s "$TEMPDIR/$libs_name.patch"; then
        slogcmd "$PATCH -p1 -N < $TEMPDIR/$libs_name.patch" || die "patch inlined failed."
    fi
}

# compile target
compile() {
    # initial build args
    if test -z "$CCACHE_DISABLE"; then
        # only compile job need ccache
        which ccache &>/dev/null    || CCACHE_DISABLE=1
        [ "$CMDLET_CCACHE" -ne 0 ]  || CCACHE_DISABLE=1

    fi

    if test -z "$CCACHE_DISABLE" && test -z "$CCACHE_DIR"; then
        CC="ccache $CC"
        CXX="ccache $CXX"
        # make clean should not clear ccache
        CCACHE_DIR="$_ROOT/.ccache/$_ARCH"
        export CC CXX CCACHE_DIR
    fi
    export CCACHE_DISABLE

    ( # always start subshell before _load()

        trap _tty_reset EXIT

        set -eo pipefail

        # prepare source codes
        _prepare || return $?

        declare -F libs_build >/dev/null || {
            slogw "<<<<<" "Not supported or missing libs_build"
            return 0
        }

        # clear and log all environments
        test -f "$_LOGFILE" && mv "$_LOGFILE" "$_LOGFILE.old" || true
        {
            echo -e "**** start build $libs_name ****\n$(date)\n"
            echo -e "PATH: $PATH\n"
            echo -e "----\n"
            env
            echo -e "----\n"
        } > "$_LOGFILE"

        # v2: clear pkgfiles
        rm -rf "$PREFIX/$libs_name"

        # v3/manifest: name pkgfile sha build=1
        touch "$_MANIFEST"

        # read pkgbuild before clear
        _PKGBUILD=$(grep " $libs_name/.*@$libs_ver" "$_MANIFEST" | tail -n1 | grep -oE "build=[0-9]+" )
        test -n "$_PKGBUILD" || _PKGBUILD="build=0"

        # v3: clear manifest
        sed -i "\#\ $libs_name/.*@$libs_ver#d" "$_MANIFEST"

        # build library
        ( libs_build ) || {
            sloge "<<<<<" "build $libs_name@$libs_ver failed"

            mv "$_LOGFILE" "$_LOGFILE.fail"
            tail -v "$_LOGFILE.fail"

            wait && exit 127
        }

        # update tracking file
        touch "$PREFIX/.$libs_name.d"

        slogi "<<<<<" "$libs_name@$libs_ver"
    )
}

# load libs_deps
_deps_load() {( _load "$1" &>/dev/null; echo "${libs_deps[@]}"; )}

# generate or update dependencies map
_deps_init() {
    test -z "$_DEPS_READY" || return 0

    export _DEPS_FILE="$_WORKDIR/.dependencies"

    test -f "$_DEPS_FILE" || true > "$_DEPS_FILE"

    local libs
    if test -s "$_DEPS_FILE"; then
        while IFS='/.' read -r _ libs _; do
            [[ "$libs" =~ ^_ || "$libs" == ALL ]] && continue

            # update dependency
            sed -i "/^$libs/d" "$_DEPS_FILE"
            echo "$libs $(_deps_load "$libs")" >> "$_DEPS_FILE"
        done < <(find libs -maxdepth 1 -type f -newer "$_DEPS_FILE")
    else
        for libs in libs/*.s; do
            IFS='/.' read -r _ libs _ <<< "$libs"

            [[ "$libs" =~ ^_ || "$libs" == ALL ]] && continue

            # write dependency
            echo "$libs $(_deps_load "$libs")" >> "$_DEPS_FILE"
        done
    fi
    export _DEPS_READY=1
}

depends() {
    _deps_init

    local list=() libs deps x
    while IFS=' ' read -r libs deps; do
        test -n "$deps" || continue
        is_listed "$libs" "$@" || continue

        for x in $(depends $deps) $deps; do
            is_listed "$x" "$@" && continue
            is_listed "$x" "${list[@]}" || list+=( "$x" )
        done
    done < <(IFS='|'; grep -Ew "$*" "$_DEPS_FILE")

    echo "${list[@]}"
}

# dependence (reverse dependencies)
rdepends() {
    _deps_init

    local list=() libs x
    while IFS=' ' read -r libs _; do
        is_listed "$libs" "$@" && continue

        for x in "$libs" $(rdepends "$libs"); do
            is_listed "$x" "${list[@]}" || list+=( "$x" )
        done
    done < <(IFS='|'; grep -Ew "$*" "$_DEPS_FILE")

    echo "${list[@]}"
}

_deps_sort() {
    _deps_init

    local head tail libs x
    for libs in "$@"; do
        # have dependencies => tail
        for x in $(depends "$libs"); do
            is_listed "$x" "$@" && tail+=( "$libs" ) && break
        done

        # OR append to head
        is_listed "$libs" "${tail[@]}" || head+=( "$libs" )
    done

    # sort tail again: be careful with circular dependencies
    if [ -n "${head[*]}" ] && [ "${#tail[@]}" -gt 1 ]; then
        IFS=' ' read -r -a tail < <( _deps_sort "${tail[@]}" )
    fi

    echo "${head[@]}" "${tail[@]}"
}

_deps_status() {
    _deps_init

    local sep="" sign x ret=0
    for x in "$@"; do
        if test -f "$PREFIX/.$x.d"; then
            sign="\\033[32m✔\\033[39m"
        else
            sign="\\033[31m✘\\033[39m"
            ret=1
        fi
        printf "%s%s%s" "$sep" "$x" "$sign"
        sep=", "
    done

    printf "\n"
    return $ret
}

# build targets and its dependencies
# build <lib list>
build() {
    slogi "🌹🌹🌹 cmdlets builder $(cat .version) @ ${BUILDER_NAME:-$OSTYPE} 🌹🌹🌹"
    echo ""

    echo "host   : ${_HOSTVARS[@]}"
    echo "target : ${_TARGETVARS[@]}"

    # always fetch manifest
    _fetch_unzip_pkgfile cmdlets.manifest "$_MANIFEST"
    echo ""

    local deps x i targets=() fails=()

    IFS=' ' read -r -a deps < <(depends "$@")

    # always sort dependencies
    IFS=' ' read -r -a deps < <(_deps_sort "${deps[@]}")

    # pull dependencies
    if [ "$CMDLET_NO_PKGFILES" -eq 0 ]; then
        local pkgfiles=()

        # check dependencies: libraries updated or not ready
        for x in "${deps[@]}"; do
            test -e "$PREFIX/.$x.d" || pkgfiles+=( "$x" )
            [ "$_ROOT/libs/$x.s" -nt "$PREFIX/.$x.d" ] && rm -f "$PREFIX/.$x.d" || true
        done

        pkgfiles "${pkgfiles[@]}" || true # ignore errors
    fi

    slogi "BUILD" "$*"

    test -z "${deps[*]}" || slogi ".DEPS" "$(_deps_status "${deps[@]}")"

    # check dependencies: rebuild targets
    for x in "${deps[@]}"; do
        test -e "$PREFIX/.$x.d" || targets+=( "$x" )
    done

    # sort and append targets
    targets+=( $(_deps_sort "$@") )

    # continue on error
    for i in "${!targets[@]}"; do
        echo ""
        IFS=' ' read -r -a deps < <(depends "${targets[i]}")
        slogi ">>>>>" "#$((i+1))/${#targets[@]} ${targets[i]} ( depends: $(_deps_status "${deps[@]}") )" || {
            true # ignore return value
            slogw "<<<<<" "dependencies not ready"
            fails+=( "${targets[i]}" )
            continue
        }

        time compile "${targets[i]}" || fails+=( "${targets[i]}" )
    done

    test -z "${fails[*]}" || sloge "build failed: ${fails[*]}"
}

# v3/git releases
_is_flat_repo() { [[ "$_REPO" =~ ^flat+ ]]; }

_fetch_unzip_pkgfile() {
    local zip

    test -n "$2" && zip="$2" || zip="$TEMPDIR/${1##*/}"

    mkdir -p "${zip%/*}"

    if _is_flat_repo; then
        slogi "💫 $_REPO/$_ARCH/${1##*/}"
        _curl "${_REPO#flat+}/$_ARCH/${1##*/}" "$zip" || return 1
    else
        slogi "💫 $_REPO/$_ARCH/$1"
        _curl "$_REPO/$_ARCH/$1" "$zip" || return 1
    fi

    if [[ "$zip" =~ \.tar\..*$ ]]; then
        tar -C "$PREFIX" -xvf "$zip"
        echo ""
    fi
}

_fetch_pkgfile() {
    local pkgname pkgvern pkginfo pkgfiles

    # priority: v2 > v3, no v1 package

    slogi "📦 Fetch package $1"

    # zlib@1.3.1
    IFS='@' read -r pkgname pkgvern <<< "$1"

    # v2: latest version
    : "${pkgvern:=latest}"

    pkginfo="$pkgname/pkginfo@$pkgvern"

    # prefer v2 pkginfo than v3 manifest for developers
    if ! _is_flat_repo && _fetch_unzip_pkgfile "$pkginfo"; then
        # v2: 98945d2bc86df9be328fc134e4b8bc2254aeacf1d5050fc7b3e11942b1d00671 zlib/libz@1.3.1.tar.gz
        IFS=' ' read -r -a pkgfiles < <( grep -oE " $pkgname/.*@[0-9.]+\.tar\.gz" "$TEMPDIR/pkginfo@$pkgvern" | xargs )
    else
        # v3: libz zlib/libz@1.3.1.tar.gz 7de3e57ccdef64333719f70e6523154cfe17a3618d382c386fe630bac3801bed build=1

        # v3: no pkgvern => find out latest version
        if test -z "$pkgvern" || [ "$pkgvern" = "latest" ]; then
            IFS='/@' read -r  _ _ pkgvern _ < <( grep -oE " $pkgname/.*@[0-9.]+" "$_MANIFEST" | sort -n | tail -n1 | sed 's/\.$//' )
            test -n "$pkgvern" && slogi ">> found package $pkgname@$pkgvern" || {
                slogw "🟠 no package found"
                return 1
            }
        fi

        # find all pkgfiles
        IFS=' ' read -r -a pkgfiles < <( grep -oE " $pkgname/.*@$pkgvern\.tar\.gz " "$_MANIFEST" | xargs )
    fi

    test -n "${pkgfiles[*]}" || { slogw "<< $* no pkgfile found"; return 1; }

    local x
    for x in "${pkgfiles[@]}"; do
        _fetch_unzip_pkgfile "$x" || { slogw "<< fetch $x failed"; return 1; }
    done

    touch "$PREFIX/.$pkgname.d" # mark as ready
}

pkgfiles() {
    slogi "☁️  Fetch pkgfiles $*"

    local ret=0 x
    for x in "$@"; do
        _fetch_pkgfile "$x" || ret=$?
    done

    return $?
}

# print info of a library
info() {
    _load "$1"

    if test -z "$libs_desc"; then
        libs_desc="$(grep "^#" "libs/$1.s" | grep -vE "vim:|#!" | head -n1 | sed 's/[# ]*//')"
    fi

    slogi "$libs_name: $libs_desc"
    slogi "  libs_lic: ${libs_lic:-Unknown}"
    slogi "  libs_ver: $libs_ver"
    slogi "  libs_url: $libs_url"
    slogi "    Dependencies : $(depends "$1")"
    slogi "    Dependences  : $(rdepends "$1")"
}

search() {
    slogi "Search $PREFIX"
    local x
    for x in "$@"; do
        # binaries ?
        slogi "Search binaries ..."
        find "$PREFIX/bin" -name "$x*" 2>/dev/null  | sed "s%^$_ROOT/%%"

        # libraries?
        slogi "Search libraries ..."
        find "$PREFIX/lib" -name "$x*" -o -name "lib$x*" 2>/dev/null  | sed "s%^$_ROOT/%%"

        # headers?
        slogi "Search headers ..."
        find "$PREFIX/include" -name "$x*" -o -name "lib$x*" 2>/dev/null  | sed "s%^$_ROOT/%%"

        # pkg-config?
        slogi "Search pkgconfig for $x ..."
        if $PKG_CONFIG --exists --print-errors --short-errors "$x"; then
            slogi ".Found $x @ $($PKG_CONFIG --modversion "$x")"
            echo "PREFIX  : $($PKG_CONFIG --variable=prefix "$x")"
            echo "CFLAGS  : $($PKG_CONFIG --cflags "$x" )"
            echo "LDFLAGS : $($PKG_CONFIG --static --libs "$x"   )"
        elif [[ ! "$x" =~ ^lib ]] && $PKG_CONFIG --exists --print-errors --short-errors "lib$x"; then
            slogi ".Found lib$x @ $($PKG_CONFIG --modversion "lib$x")"
            echo "PREFIX  : $($PKG_CONFIG --variable=prefix "lib$x" )"
            echo "CFLAGS  : $($PKG_CONFIG --cflags "lib$x" )"
            echo "LDFLAGS : $($PKG_CONFIG --static --libs "lib$x"   )"
        fi
    done
}

# load libname
load() {
    _load "$1"
}

# fetch libname
fetch() {
    slogi "fetch packages $*"
    local libs x
    for libs in "$@"; do
        _load "$libs"

        test -n "$libs_url" || continue

        _fetch "$(_package_name "$libs_url")" "$libs_sha" "$libs_url"

        # libs_resources: no mirrors
        if test -n "${libs_resources[*]}"; then
            local url sha
            for x in "${libs_resources[@]}"; do
                IFS=';|' read -r url sha <<< "$x"
                _fetch "$(_package_name "$url")" "$sha" "$url"
            done
        fi
    done
}

# prepare libraries source codes
prepare() {
    slogi "prepare $*"
    for x in "$@"; do
        ( _prepare "$x"; )
    done
}

arch() {
    echo "$_ARCH"
}

# zip files for release actions
zip_files() {
    # log files
    test -n "$(ls -A "$_LOGFILES")" || return 0
    "$TAR" -C "$_LOGFILES" -cf "$_LOGFILES-logs.tar.gz" .
}

env() {
    /usr/bin/env | grep -v "^PROMPT"
}

gcc.macros() {
    echo | "$CC" -dM -E -
}

clean() {
    rm -rf "$_WORKDIR" "$_LOGFILES"
    exit 0 # always exit here
}

distclean() {
    rm -rf "$PREFIX" && clean || true
}

check() {
    local list=() x

    IFS=' ' read -r -a list < <(rdepends "$@")

    build "$@" "${list[@]}"
}

# update libs to new version or die
#  input: name version
update() {
    _load "$1"

    slogi ">>>>> update $1 $libs_ver => $2 <<<<<"
    sed -i "libs/$1.s" \
        -e "/libs_ver=/,/libs_build/s/$libs_ver/$2/g" \
        -e "/libs_sha=/s/=.*$/=/" || die

    # load again
    _load "$1"

    # load again and fetch
    _fetch "$(_package_name "$libs_url")" "$libs_sha" "${libs_url[@]}" || die

    IFS=' ' read -r sha _ < <(sha256sum "$(_package_name "$libs_url")")
    sed "s/libs_sha=.*$/libs_sha=$sha/" -i "libs/$1.s"

    slogw "<<<<< updated $libs_name => $libs_ver >>>>>"
}

_on_exit() {
    # show ccache statistics
    test -z "$CCACHE_DIR" || ccache -d "$CCACHE_DIR" -s

    rm -rf "$TEMPDIR"
}

TEMPDIR="$(mktemp -d)" && trap _on_exit EXIT

_init || exit 110

case "$0" in
    bash)       return 0    ;;
    *libs.sh$)  "$@"        ;;
    *)
        func="${0##*/}"
        declare -F $func &>/dev/null || die "$func not exists."
        "$func" "$@"
        ;;
esac
exit $?

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
