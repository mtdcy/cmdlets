#!/bin/bash

# shellcheck shell=bash
# shellcheck disable=SC2154

set -e -o pipefail

umask  0022
export LANG=C

# options           =
export      CL_FORCE=${CL_FORCE:-0}         # force rebuild all dependencies
export    CL_LOGGING=${CL_LOGGING:-tty}     # tty,plain,silent
export     CL_STRICT=${CL_STRICT:-0}        # check on file changes on libs.sh
export    CL_MIRRORS=${CL_MIRRORS:-}        # package mirrors, and go/cargo/etc
export     CL_CCACHE=${CL_CCACHE:-0}        # enable ccache or not
export      CL_NJOBS=${CL_NJOBS:-1}         # noparallel by default

# toolchain prefix
export CL_TOOLCHAIN_PREFIX=${CL_TOOLCHAIN_PREFIX:-$(uname -m)-unknown-linux-musl-}

# clear envs => setup by _init
unset ROOT PREFIX WORKDIR

# conditionals
is_darwin()     { [[ "$OSTYPE" =~ darwin ]];                            }
is_msys()       { [[ "$OSTYPE" =~ msys ]] || test -n "$MSYSTEM";        }
is_linux()      { [[ "$OSTYPE" =~ linux ]];                             }
is_glibc()      { ldd --version 2>&1 | grep -qFi "glibc";               }
# 'ldd --version' in alpine always return 1
is_musl()       { { ldd --version 2>&1 || true; } | grep -qF "musl";    }
is_clang()      { $CC --version 2>/dev/null | grep -qF "clang";         }
is_arm64()      { uname -m | grep -q "arm64\|aarch64";                  }
is_musl_gcc()   { [[ "$CC" =~ musl-gcc$ ]];                             }

# slog [error|info|warn] "leading" "message"
_slog() {
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
    echo -e "$message"
}

slogi() { _slog info  "$@" >&2;             }
slogw() { _slog warn  "$@" >&2;             }
sloge() { _slog error "$@" >&2; return 1;   }

die()   { _slog error "$@" >&2; exit 1;     } # exit shell

# for subshell
# write error message to .ERR_MSG on failure
_on_failure() {
    echo "$*" >> "$PREFIX/.ERR_MSG"
    exit 1 # exit subshell
}

# for main shell
_exit_on_failure() {
    test -s "$PREFIX/.ERR_MSG" && die "$(cat "$PREFIX/.ERR_MSG" | xargs)"
}

_capture() {
    if [ "$CL_LOGGING" = "silent" ]; then
        cat >> "$_LOGFILE"
    elif [ "$CL_LOGGING" = "tty" ] && test -t 1 && which tput &>/dev/null; then
        tput dim                        # dim on
        tput rmam                       # line break off

        local i=0
        while read -r line; do
            i=$((i + 1))

            tput ed                     # clear to end of screen
            tput sc                     # save cursor position
            printf "#$i: %s" "$line"
            tput rc                     # restore cursor position
        done < <(tee -a "$_LOGFILE")

        tput ed                         # clear to end of screen
        tput smam                       # line break on
        tput sgr0                       # reset colors
    else
        tee -a "$_LOGFILE"
    fi
}

# why eval as string?
#  Pros:
#   slogcmd "$PATCH -p1 -N < $file"     # redirect evals well
#   pkgfile git bin/git bin/git-*       # glob works fine
#
#  Cons:
#   --prefix="'$PREFIX'"                # must be quoted twice
echocmd() {
    {
        echo "$@"
        eval -- "$*"
    } 2>&1 | CL_LOGGING=${CL_LOGGING:-silent} _capture
}

# slogcmd <command>
slogcmd() {
    slogi "..Run" "$@"
    echocmd "$@"
}

# find out executables and export envs
#  input: name:file ...
#  ENV: COMMAND='xcrun --find'
_init_tools() {
    local cmd="${COMMAND:-which}"
    local k v p
    for x in "$@"; do
        IFS=':' read -r k v <<< "$x"

        for y in ${v//,/ }; do
            p="$(eval "$cmd" "$y" 2>/dev/null)" && break
        done

        [ -n "$p" ] || slogw "Init:" "missing host tools ${v[*]}"

        export "$k=$p"
    done
}

_init() {
    [ -z "$ROOT" ] && ROOT="$(pwd -P)" || return 0

    mkdir -p "$ROOT"/{prebuilts,out,logs,packages}

    local arch
    if [ "$(uname -s)" = Darwin ]; then
        arch="$(uname -m)-apple-darwin"
    elif test -n "$MSYSTEM"; then
        arch="$(uname -m)-msys-${MSYSTEM,,}"
    #elif ldd --version 2>/dev/null | grep -qFw musl; then
    #    arch="$(uname -m)-linux-musl"
    else
        arch="$(uname -m)-$OSTYPE"
    fi

    # prepare directories and files
    PREFIX="$ROOT/prebuilts/$arch"
    WORKDIR="$ROOT/out/$arch"
    LOGFILES="$ROOT/logs/$arch"

    mkdir -p "$PREFIX"/{bin,include,lib{,/pkgconfig}} "$WORKDIR" "$LOGFILES"

    true > "$PREFIX/.ERR_MSG" # create a zero sized file

    export ROOT PREFIX WORKDIR LOGFILES

    is_glibc || unset CL_TOOLCHAIN_PREFIX

    # shellcheck disable=SC2054,SC2206
    local toolchains=(
        CC:${CL_TOOLCHAIN_PREFIX}gcc
        CXX:${CL_TOOLCHAIN_PREFIX}g++
        AR:${CL_TOOLCHAIN_PREFIX}ar
        AS:${CL_TOOLCHAIN_PREFIX}as
        LD:${CL_TOOLCHAIN_PREFIX}ld
        NM:${CL_TOOLCHAIN_PREFIX}nm
        RANLIB:${CL_TOOLCHAIN_PREFIX}ranlib
        STRIP:${CL_TOOLCHAIN_PREFIX}strip
    )
    if is_darwin; then
        COMMAND="xcrun --find" _init_tools "${toolchains[@]}"
    else
        _init_tools "${toolchains[@]}"
    fi

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
        "PKG_CONFIG:pkg-config"
        "PATCH:patch"
        "INSTALL:install"
        "TAR:gtar,tar"
    )

    is_arm64 || host_tools+=(
        NASM:nasm
        YASM:yasm
    )

    # MSYS2
    is_msys && host_tools+=(
        # we are using MSYS shell, but still setup mingw32-make
        MMAKE:mingw32-make.exe
        RC:windres.exe
    )

    _init_tools "${host_tools[@]}"

    # common flags for c/c++
    local FLAGS=(
        -g0 -Os             # optimize for size
        -fPIC -DPIC         # PIC
    )

    # macOS does not support statically linked binaries
    if is_darwin; then
        FLAGS+=( -Wno-error=deprecated-non-prototype )
        LDFLAGS="-L$PREFIX/lib -Wl,-dead_strip"
    else
        # static linking => two '--' vs ldflags
        FLAGS+=( --static )

        # tell compiler to place each function and data into its own section
        is_msys || FLAGS+=(
            -ffunction-sections
            -fdata-sections
        )

        LDFLAGS="-L$PREFIX/lib -static -static-libstdc++ -static-libgcc"

        # remove unused sections, need -ffunction-sections and -fdata-sections
        LDFLAGS+=" -Wl,-gc-sections"

        # pie => cause 'read-only segment has dynamic relocations' error
        #  => use PIC instead, or let packages decide
        #LDFLAGS+=" -fPIE -pie"

        # link needed static libraries
        is_msys || LDFLAGS+=" -Wl,--as-needed -Wl,-Bstatic"

        # Security: FULL RELRO
        is_msys || LDFLAGS+=" -Wl,-z,relro,-z,now"
    fi

    CFLAGS="${FLAGS[*]}"
    CXXFLAGS="${FLAGS[*]}"
    CPP="$CC -E"
    CPPFLAGS="-I$PREFIX/include"

    export CFLAGS CXXFLAGS CPP CPPFLAGS LDFLAGS

    # pkg-config
    export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

    # for running test
    # LD_LIBRARY_PATH or rpath?
    export LD_LIBRARY_PATH=$PREFIX/lib

    # export again after cmake and others
    export PKG_CONFIG="$PKG_CONFIG --define-variable=PREFIX=$PREFIX --static"

    # ccache
    if [ "$CL_CCACHE" -ne 0 ] && which ccache &>/dev/null; then
        CC="ccache $CC"
        CXX="ccache $CXX"
        # make clean should not clear ccache
        CCACHE_DIR="$ROOT/.ccache/$arch"
        export CC CXX CCACHE_DIR
    else
        export CCACHE_DISABLE=1
    fi

    # macos
    if is_darwin; then
        export MACOSX_DEPLOYMENT_TARGET=11.0
    elif is_msys; then
        export MSYS=winsymlinks:lnk
    fi

    # cmdlets
    [ -z "$CL_MIRRORS" ] || export CMDLETS_MAIN_REPO="$CL_MIRRORS/cmdlets/latest"
}

# link source target
_link() {
    #echo "link: $1 => $2" >&2
    if is_msys; then
        echocmd cp -v "$1" "$2"
    else
        echocmd ln -srvf "$1" "$2"
    fi
}

# _curl source destination [options]
_curl() {
    local source="$1"

    if test -n "$2"; then
        curl -fsI "${@:3}" "$source" -o /dev/null &&
        # show errors
        echocmd curl -fvSL "${@:3}" "$source" -o "$2"
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
        slogi ".FILE" "$zip"

        # verify sha only if it exists
        test -n "$2" || return 0

        IFS=' *' read -r _sha _ <<< "$(sha256sum "$zip")"
        if [ "$_sha" = "$sha" ]; then
            return 0
        else
            slogw "..SHA" "$_sha vs $sha (expected)"
            rm -f "$zip"
        fi
    fi

    #2. try mirror
    if test -n "$CL_MIRRORS"; then
        mirror="$CL_MIRRORS/packages/$libs_name/${zip##*/}"
        slogi ".CURL" "$mirror"
        _curl "$mirror" "$zip" ||
        rm -f "$zip"
    fi

    #3. try originals
    if ! test -f "$zip"; then
        for url in "${@:3}"; do
            slogi ".CURL" "$url"
            _curl "$url" "$zip" && break || rm -f "$zip"
        done
    fi

    test -f "$zip" || die "curl $1 failed."

    slogi ".FILE" "$(sha256sum "$zip")"
    return 0
}

# unzip file to current dir, or exit program
# _unzip <file> [strip]
_unzip() {
    slogi ".Zipx" "$1 => $(pwd)"

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
    CL_LOGGING=silent echocmd "${cmd[@]}" "$1" || die "unzip $1 failed."

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
_git() {
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

_packages() {
    # https://github.com/webmproject/libwebp/archive/refs/tags/v1.6.0.tar.gz
    if [[ "${1##*/}" =~ ^v?[0-9.]{2} ]]; then
        local path
        IFS=':/' read -r _ _ _ _ path <<< "$1"
        echo "$ROOT/packages/$libs_name/${path//\//_}"
    else
        echo "$ROOT/packages/$libs_name/${1##*/}"
    fi
}

# unzip url to workdir or die
#  input: sha url [mirrors...]
_fetch_unzip() {
    # e.g: libs_url="https://github.com/docker/cli.git#v$libs_ver"
    if [[ "${2%#*}" =~ \.git$ ]]; then
        _git "${@:2}" "${2##*/}"
    else
        # assemble zip name from url
        local zip="$(_packages "$2")"

        # download zip file
        _fetch "$zip" "$1" "${@:2}"
        # unzip to current fold
        _unzip "$zip" "${ZIP_SKIP:-}"
    fi
}

# prepare source code or die
_prepare() {
    # libs_url: support mirrors
    _fetch_unzip "$libs_sha" "${libs_url[@]}"

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
                local file="$(_packages "$patch")"
                test -f "$file" || _curl "$patch" "$file"
                slogcmd "$PATCH -p1 -N < $file" || die "patch < $file failed."
                ;;
            *)
                slogcmd "$PATCH -p1 -N < $patch" || die "patch < $patch failed."
                ;;
        esac
    done

    if test -s "$TEMPDIR/$libs_name.patch"; then
        slogcmd "$PATCH -p1 -N < $TEMPDIR/$libs_name.patch" || die "patch inlined failed."
    fi
}

# _load library
_load() {
    unset "${!libs_@}"

    local file="libs/$1.s"

    # sed: delete all lines after __END__
    sed '/__END__/Q' "$file" > "$TEMPDIR/$1.s"

    . "$TEMPDIR/$1.s"

    # default values:
    [ -n "$libs_name" ] || libs_name="$1"

    sed '1,/__END__/d' "$file" > "$TEMPDIR/$libs_name.patch"
}

# compile target
compile() {
    export _LOGFILE="$LOGFILES/${1##*/}.log"

    # always start subshell before _load()
    (
        set -eo pipefail

        . helpers.sh

        slogi ".Load" "$1"
        _load "$1"

        if [ "$libs_type" = ".PHONY" ]; then
            slogw "<<<<<" "skip dummy target $libs_name"
            return 0
        fi

        test -n "$libs_url" || die "missing libs_url"

        # prepare work dir
        mkdir -p "$PREFIX"
        mkdir -p "${_LOGFILE%/*}"

        local workdir="$WORKDIR/$libs_name-$libs_ver"

        # strict mode: clean before compile
        [ "$CL_STRICT" -eq 0 ] || rm -rf "$workdir"

        mkdir -p "$workdir" && cd "$workdir"

        # clear logfile
        echo -e "**** start build $libs_name ****\n$(date)\n" > "$_LOGFILE"

        slogi ".Path" "$PWD"

        _prepare # or die

        # clear pkginfo
        rm -rf "$PREFIX/$libs_name"

        # clear manifest
        touch "$PREFIX/cmdlets.manifest"
        sed -i "\#\ $libs_name/.*@$libs_ver#d" "$PREFIX/cmdlets.manifest"

        # build library
        libs_build || die "build $libs_name@$libs_ver failed"

        # update tracking file
        touch "$PREFIX/.$libs_name.d"

        slogi "<<<<<" "$libs_name@$libs_ver"
    ) || {
        sleep 1 # let _capture() finish

        mv "$_LOGFILE" "$_LOGFILE.fail"
        tail -v "$_LOGFILE.fail"
        exit 127
    }
}

_load_deps() {( _load "$1" &>/dev/null; echo "${libs_dep[@]}"; )}

# _deps_get libname
_deps_get() {
    local list=()

    IFS=' ' read -r -a deps <<< "$(_load_deps "$1")"

    [[ "${deps[*]}" == *"$1"* ]] && {
        _on_failure "bad self-depends: $1 @ ${deps[*]}"
    }

    for dep in "${deps[@]}"; do
        # already exists?
        [[ "${list[*]}" == *"$dep"* ]] && continue

        IFS=' ' read -r -a _deps <<< "$(_deps_get "$dep")"

        for x in "${_deps[@]}"; do
            [[ "${list[*]}" == *"$x"* ]] || list+=( "$x" )
        done

        list+=( "$dep" )
    done
    echo "${list[@]}"
}

# check dependencies for libraries
_check_deps() {
    local deps=()

    for ulib in "$@"; do
        IFS=' ' read -r -a _deps <<< "$(_deps_get "$ulib")"

        for x in "${_deps[@]}"; do
            # dependencies in targets
            [[ "$*" == *"$x"* ]] && continue
            # already exists?
            [[ "${deps[*]}" == *"$x"* ]] && continue

            #1. dep not installed
            #2. dep.s been updated
            #3. libs.sh been updated (CL_STRICT)
            if [ ! -e "$PREFIX/.$x.d" ] || [ "$ROOT/libs/$x.s" -nt "$PREFIX/.$x.d" ]; then
                deps+=( "$x" )
            #elif [ "$CL_STRICT" -ne 0 ] && [ "libs.sh" -nt "$PREFIX/.$x.d" ]; then
            #    deps+=( "$x" )
            fi
        done
    done

    [ "${#deps[@]}" -gt 1 ] && _sort_by_depends "${deps[@]}" || echo "${deps[@]}"
}

_sort_by_depends() {
    local head=()
    local tail=()
    for ulib in "$@"; do
        IFS=' ' read -r -a _deps <<< "$(_deps_get "$ulib")"

        for x in "${_deps[@]}"; do
            # have dependencies => append
            if [[ "$*" == *"$x"* ]]; then
                tail+=( "$ulib" )
                break
            fi
        done

        # OR prepend
        [[ "${tail[*]}" == *"$ulib"* ]] || head+=( "$ulib" )
    done

    # sort tail again: be careful with circular dependencies
    if [ -n "${head[*]}" ] && [ "${#tail[@]}" -gt 1 ]; then
        IFS=' ' read -r -a tail <<< "$(_sort_by_depends "${tail[@]}")"
    fi

    echo "${head[@]}" "${tail[@]}"
}

# build targets and its dependencies
# build <lib list>
build() {
    slogi "$*"

    IFS=' ' read -r -a deps <<< "$(_check_deps "$@")"

    _exit_on_failure

    slogi "dependencies: ${deps[*]}"

    CMDLETS_PREBUILTS=$PREFIX ./cmdlets.sh manifest &>/dev/null || true

    # pull dependencies
    local targets=()
    if [ "$CL_FORCE" -ne 0 ]; then
        slogi "Force rebuild dependencies"
        targets=( "${deps[@]}" )
    else
        CMDLETS_PREBUILTS=$PREFIX ./cmdlets.sh package "${deps[@]}"

        for dep in "${deps[@]}"; do
            [ -e "$PREFIX/.$dep.d" ] || targets+=( "$dep" )
        done

        _rm_libtool_archive
    fi

    # append targets
    targets+=( "$@" )

    if [ "${#targets[@]}" -gt 1 ]; then
        IFS=' ' read -r -a targets <<< "$(_sort_by_depends "${targets[@]}")"
    fi

    _exit_on_failure

    slogi "Build" "${targets[*]}"

    for i in "${!targets[@]}"; do
        slogi ">>>>>" "#$((i+1))/${#targets[@]} ${targets[i]}"

        time compile "${targets[i]}" || die "build ${targets[i]} failed."
    done
}

search() {
    slogi "Search $PREFIX"
    for x in "$@"; do
        # binaries ?
        slogi "Search binaries ..."
        find "$PREFIX/bin" -name "$x*" 2>/dev/null  | sed "s%^$ROOT/%%"

        # libraries?
        slogi "Search libraries ..."
        find "$PREFIX/lib" -name "$x*" -o -name "lib$x*" 2>/dev/null  | sed "s%^$ROOT/%%"

        # headers?
        slogi "Search headers ..."
        find "$PREFIX/include" -name "$x*" -o -name "lib$x*" 2>/dev/null  | sed "s%^$ROOT/%%"

        # pkg-config?
        slogi "Search pkgconfig for $x ..."
        if $PKG_CONFIG --exists "$x"; then
            slogi ".Found $x @ $($PKG_CONFIG --modversion "$x")"
            echo "PREFIX : $($PKG_CONFIG --variable=prefix "$x")"
            echo "CFLAGS : $($PKG_CONFIG --cflags "$x" )"
            echo "LDFLAGS: $($PKG_CONFIG --libs "$x"   )"
            # TODO: add a sanity check here
        fi

        [[ "$x" =~ ^lib ]] && continue

        x=lib$x
        slogi "Search pkgconfig for $x ..."
        if $PKG_CONFIG --exists "$x"; then
            slogi ".Found $x @ $($PKG_CONFIG --modversion "$x")"
            echo "PREFIX : $($PKG_CONFIG --variable=prefix "$x" )"
            echo "CFLAGS : $($PKG_CONFIG --cflags "$x" )"
            echo "LDFLAGS: $($PKG_CONFIG --libs "$x"   )"
            # TODO: add a sanity check here
        fi
    done
}

# find out dependencies of library
info() {
    slogi "$1: $(_deps_get "$1")"

    for lib in libs/*.s; do
        IFS='/.' read -r _ ulib _ <<< "$pkg"

        [[ "$libs" =~ ^[\.@_] ]] && continue

        IFS=' ' read -r -a deps <<< "$(bash libs.sh _load_deps "$lib")"

        if [[ "${deps[*]}" == *"$1"* ]]; then
            slogi "$lib => $1"
        fi
    done
}

# load libname
load() {
    _load "$1"
}

# fetch libname
fetch() {
    _load "$1"

    _fetch "$(_packages "$libs_url")" "$libs_sha" "$libs_url"
}

arch() {
    "${PREFIX##*/}"
}

# zip files for release actions
zip_files() {
    # manifest
    cd "$PREFIX" && "$TAR" -cvf "cmdlets.manifest.tar.gz" cmdlets.manifest && cd - || true

    # log files
    test -n "$(ls -A "$LOGFILES")" || return 0
    "$TAR" -C "$LOGFILES" -cvf "$LOGFILES-logs.tar.gz" .
}

env() {
    /usr/bin/env | grep -v "^PROMPT"
}

clean() {
    rm -rf "$WORKDIR" "$LOGFILES"
}

distclean() {
    clean
    rm -rf "$PREFIX"
}

# speed up prepare-host by making prerequisites.tar.gz
#  input: [url]
prerequisites() {
    test -f "$PREFIX/prerequisites-0" && return 0

    # no prerequisites except for brew on macOS
    which brew || return 0

    # for _capture
    export libs_name=prerequisites

    cd "$PREFIX"
    if test -n "$1"; then
        for i in {0..9}; do
            _curl "$1/${PREFIX##*/}/prerequisites-$i" "prerequisites-$i" || break
        done

        if test -f prerequisites-0; then
            cat prerequisites-* | tar -C / -xz
        fi
    else
        mkdir -pv "$libs_name" && cd "$libs_name"
        tar -C / -czf "prerequisites.tar.gz" "$(brew --prefix)"
        split -b 1G -d -a 1 prerequisites.tar.gz prerequisites-
        rm prerequisites.tar.gz
    fi
}

# shellcheck disable=SC2064
TEMPDIR="$(mktemp -d)" && trap "rm -rf $TEMPDIR" EXIT

_init || exit 110

if [[ "$0" =~ libs.sh$ ]]; then
    cd "$(dirname "$0")" && "$@" || exit $?
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
