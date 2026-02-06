#!/bin/bash

# shellcheck shell=bash
# shellcheck disable=SC2154
# shellcheck disable=SC2031

set -e -o pipefail

umask  0022
export LANG=C

# public options      =
        CMDLET_LOGGING=${CMDLET_LOGGING:-tty}       # tty,plain,silent
        CMDLET_MIRRORS=${CMDLET_MIRRORS:-}          # package mirrors, and go/cargo/etc
         CMDLET_CCACHE=${CMDLET_CCACHE:-0}          # enable ccache or not
           CMDLET_REPO=${CMDLET_REPO:-}             # cmdlet pkgfiles repo

# public build options  =
      CMDLET_BUILD_NJOBS=${CMDLET_BUILD_NJOBS:-1}   # no parallel build by default
      CMDLET_BUILD_FORCE=${CMDLET_BUILD_FORCE:-0}   # force build dependencies
 CMDLET_TOOLCHAIN_PREFIX=${CMDLET_TOOLCHAIN_PREFIX:-}

# toolchain prefix

# set private vairables
: "${_LOGGING:=$CMDLET_LOGGING}"

: "${_REPO:=$CMDLET_REPO}"
: "${_REPO:=https://pub.mtdcy.top/cmdlets/latest}"

# mirrors
: "${_MIRRORS:=$CMDLET_MIRRORS}"
if test -n "$_MIRRORS"; then
    : "${_CARGO_REGISTRY:=$_MIRRORS/crates.io-index/}"
    : "${_GO_PROXY:=$_MIRRORS/gomods}"
fi

# build args
: "${_NJOBS:=$CMDLET_BUILD_NJOBS}"

# clear envs => setup by _init
unset _ROOT _WORKDIR PREFIX
# => PREFIX is a widely used variable

# defaults
: "${MACOSX_DEPLOYMENT_TARGET:=11.0}"
# check: otool -l <path_to_binary> | grep minos

# conditionals
is_darwin()     { [[ "$OSTYPE" =~ darwin ]];                            }
is_msys()       { [[ "$OSTYPE" =~ msys ]] || test -n "$MSYSTEM";        }
is_linux()      { [[ "$OSTYPE" =~ linux ]];                             }
is_glibc()      { $CC -v 2>&1 | grep -q "^Target:.*gnu";                }
is_musl()       { $CC -v 2>&1 | grep -q "^Target:.*musl";               }
is_clang()      { $CC -v 2>&1 | grep -qF "clang";                       }
is_arm64()      { uname -m | grep -q "arm64\|aarch64";                  }
is_intel()      { uname -m | grep -qF "x86_64";                         }

# help functions
is_listed()     { [[ " ${*:2} " == *" $1 "* ]];     }   # is $1 in list ${@:2}?

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
    echo -e "$message" >&2
}

slogi() { _slog info  "$@";             }
slogw() { _slog warn  "$@";             }
sloge() { _slog error "$@"; return 1;   }

die()   {
    _tty_reset # in case Ctrl-C happens
    _slog error "$@"
    exit 1 # exit shell
}

_capture() {
    if [ "$_LOGGING" = "tty" ]; then
        test -t 1 && which tput &>/dev/null || unset _LOGGING
    fi

    if [ "$_LOGGING" = "tty" ]; then
        tput dim                        # dim on
        tput rmam                       # line break off
    fi

    case "$_LOGGING" in
        silent)
            cat >> "$_LOGFILE"
            ;;
        tty)
            local i=0
            while read -r line; do
                i=$((i+1))

                tput ed                     # clear to end of screen
                tput sc                     # save cursor position
                printf "#$i: %s" "$line"
                tput rc                     # restore cursor position
            done < <(tee -a "$_LOGFILE")
            ;;
        *)
            tee -a "$_LOGFILE"
            ;;
    esac

    [ "$_LOGGING" = "tty" ] && _tty_reset || true
}

_tty_reset() {
    [ "$_LOGGING" = "tty" ] || return 0

    tput ed         # clear to end of screen
    tput smam       # line break on
    tput sgr0       # reset colors
}

_capture_stderr() {
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

# find out executables and export envs
#  input: name:file ...
#  ENV: COMMAND='xcrun --find'
_init_tools() {
    local cmd="${COMMAND:-which}"
    local k v p x y
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
    test -z "$_ROOT" || return 0

    _ROOT="$(pwd -P)"

    if [ "$(uname -s)" = Darwin ]; then
        _ARCH="$(uname -m)-apple-darwin"
    elif test -n "$MSYSTEM"; then
        _ARCH="$(uname -m)-msys-${MSYSTEM,,}"
    #elif ldd --version 2>/dev/null | grep -qFw musl; then
    #    _ARCH="$(uname -m)-linux-musl"
    else
        _ARCH="$(uname -m)-$OSTYPE"
    fi

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

    # toolchain
    : "${_TOOLCHAIN:=$CMDLET_TOOLCHAIN_PREFIX}"
    test -n "$_TOOLCHAIN" && which "$_TOOLCHAIN"gcc &>/dev/null || unset _TOOLCHAIN

    # check musl-gcc
    : "${_TOOLCHAIN:=$(uname -m)-unknown-$(uname -s | tr A-Z a-z)-musl-}"
    test -n "$_TOOLCHAIN" && which "$_TOOLCHAIN"gcc &>/dev/null || unset _TOOLCHAIN

    export _TOOLCHAIN

    # shellcheck disable=SC2054,SC2206
    local toolchains=(
        CC:${_TOOLCHAIN}gcc
        CXX:${_TOOLCHAIN}g++
        AR:${_TOOLCHAIN}ar
        AS:${_TOOLCHAIN}as
        LD:${_TOOLCHAIN}ld
        NM:${_TOOLCHAIN}nm
        RANLIB:${_TOOLCHAIN}ranlib
        STRIP:${_TOOLCHAIN}strip
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
        FLAGS+=(
            -Wno-deprecated-non-prototype
            -mmacosx-version-min="$MACOSX_DEPLOYMENT_TARGET"
        )
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
    OBJCFLAGS="${FLAGS[*]}"
    OBJC="$CC"
    CPP="$CC -E"
    CPPFLAGS="-I$PREFIX/include"

    export CFLAGS OBJCFLAGS CXXFLAGS OBJC CPP CPPFLAGS LDFLAGS

    # some build system do not support pkg-config with parameters
    #export PKG_CONFIG="$PKG_CONFIG --define-variable=PREFIX=$PREFIX --static"
    PKG_CONFIG_LIBDIR="$PREFIX/lib"
    PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
    # XXX: not all build system support multiple pkgconfig dirs, fix install scripts later
    #PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig"

    export PKG_CONFIG PKG_CONFIG_PATH PKG_CONFIG_LIBDIR

    # scripts override
    #  input: script env
    _init_scripts() {
        eval export REAL_$2="\$$2"
        eval export $2="$_ROOT/scripts/$1"
    }
    #PKG_CONFIG="$_ROOT/scripts/pkg-config"
    _init_scripts pkg-config PKG_CONFIG

    # update PATH => tools like glib-compile-resources needs seat in PATH
    export PATH="$PREFIX/bin:$PATH"

    # for running test
    # LD_LIBRARY_PATH or rpath?
    #export LD_LIBRARY_PATH=$PREFIX/lib
    # rpath is meaningless for static libraries and executables, and
    # to avoid link shared libraries accidently, undefine LD_LIBRARY_PATH
    # will help find out the mistakes.

    # ccache
    if [ "$CMDLET_CCACHE" -ne 0 ] && which ccache &>/dev/null; then
        CC="ccache $CC"
        CXX="ccache $CXX"
        # make clean should not clear ccache
        CCACHE_DIR="$_ROOT/.ccache/$_ARCH"
        export CC CXX CCACHE_DIR
    else
        export CCACHE_DISABLE=1
    fi

    # macos
    export MACOSX_DEPLOYMENT_TARGET
    # msys
    export MSYS=winsymlinks:lnk
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
    if test -n "$_MIRRORS"; then
        mirror="$_MIRRORS/packages/$libs_name/${zip##*/}"
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

        if file "$zip" | grep -Fwq "text"; then
            # copy ASCII text file directly
            cp -f "$zip" .
        else
            # unzip to current fold
            _unzip "$zip" "${ZIP_SKIP:-}"
        fi
    fi
}

# prepare source code or die
_prepare() {
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

    sed '1,/__END__/d' "$file" > "$TEMPDIR/$libs_name.patch"

    # prepare logfile
    mkdir -p "$_LOGFILES"
    export _LOGFILE="$_LOGFILES/$libs_name.log"
}

# compile target
compile() {
    ( # always start subshell before _load()
        # initial build args

        trap _tty_reset EXIT

        set -eo pipefail

        _load "$1"

        # clear logfiles
        test -f "$_LOGFILE" && mv "$_LOGFILE" "$_LOGFILE.old" || true

        if [ "$libs_type" = ".PHONY" ]; then
            slogw "<<<<<" "skip dummy target $libs_name"
            return 0
        fi

        declare -F libs_build >/dev/null || {
            slogw "<<<<<" "Not supported or missing libs_build"
            return 0
        }

        test -n "$libs_url" || die "missing libs_url"

        # prepare work directories
        local workdir="$_WORKDIR/$libs_name-$libs_ver"

        mkdir -p "$PREFIX"
        mkdir -p "$workdir" && cd "$workdir"

        # clear logfile
        echo -e "**** start build $libs_name ****\n$(date)\n" > "$_LOGFILE"

        slogi ".Path" "${PWD#"$_ROOT/"}"

        _prepare # or die

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
            sloge "build $libs_name@$libs_ver failed"

            sleep 1 # let _capture() finish

            mv "$_LOGFILE" "$_LOGFILE.fail"
            tail -v "$_LOGFILE.fail"

            exit 127
        }

        # update tracking file
        touch "$PREFIX/.$libs_name.d"

        slogi "<<<<<" "$libs_name@$libs_ver"
    )
}

# load libs_deps
_deps_load() {( _load "$1" &>/dev/null; echo "${libs_dep[@]}"; )}

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

    local sep="" sign x
    for x in "$@"; do
        test -f "$PREFIX/.$x.d" && sign="\\033[32m✔\\033[39m" || sign="\\033[31m✘\\033[39m"
        printf "%s%s%s" "$sep" "$x" "$sign"
        sep=", "
    done

    printf "\n"
}

# build targets and its dependencies
# build <lib list>
build() {
    local deps x i targets=()

    IFS=' ' read -r -a deps < <(depends "$@")

    # always sort dependencies
    IFS=' ' read -r -a deps < <(_deps_sort "${deps[@]}")

    # check dependencies: libraries updated

    # pull dependencies
    if [ "$CMDLET_BUILD_FORCE" -ne 0 ]; then
        # check dependencies: force update
        for x in "${deps[@]}"; do
            rm -f "$PREFIX/.$x.d"
        done
    else
        local pkgfiles=()

        # check dependencies: libraries updated or not ready
        for x in "${deps[@]}"; do
            test -e "$PREFIX/.$x.d" || pkgfiles+=( "$x" )
            [ "$_ROOT/libs/$x.s" -nt "$PREFIX/.$x.d" ] && rm -f "$PREFIX/.$x.d" || true
        done

        pkgfiles "${pkgfiles[@]}" || true # ignore errors
    fi

    slogi "Build" "$* ( depends: $(_deps_status "${deps[@]}") )"

    # check dependencies: rebuild targets
    for x in "${deps[@]}"; do
        test -e "$PREFIX/.$x.d" || targets+=( "$x" )
    done

    # append targets
    targets+=( $(_deps_sort "$@") )

    for i in "${!targets[@]}"; do
        slogi ">>>>>" "#$((i+1))/${#targets[@]} ${targets[i]}"

        time compile "${targets[i]}" || die "build ${targets[i]} failed."
    done
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

    _fetch_unzip_pkgfile cmdlets.manifest "$_MANIFEST"

    echo ""

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
        if $PKG_CONFIG --exists "$x"; then
            slogi ".Found $x @ $($PKG_CONFIG --modversion "$x")"
            echo "PREFIX : $($PKG_CONFIG --variable=prefix "$x")"
            echo "CFLAGS : $($PKG_CONFIG --cflags "$x" )"
            echo "LDFLAGS: $($PKG_CONFIG --static --libs "$x"   )"
        elif $PKG_CONFIG --exists "lib$x"; then
            x="lib$x"

            slogi ".Found $x @ $($PKG_CONFIG --modversion "$x")"
            echo "PREFIX : $($PKG_CONFIG --variable=prefix "$x" )"
            echo "CFLAGS : $($PKG_CONFIG --cflags "$x" )"
            echo "LDFLAGS: $($PKG_CONFIG --static --libs "$x"   )"
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

arch() {
    echo "$_ARCH"
}

# zip files for release actions
zip_files() {
    # log files
    test -n "$(ls -A "$_LOGFILES")" || return 0
    "$TAR" -C "$_LOGFILES" -cvf "$_LOGFILES-logs.tar.gz" .
}

env() {
    /usr/bin/env | grep -v "^PROMPT"
}

clean() {
    rm -rf "$_WORKDIR" "$_LOGFILES"
    exit 0 # always exit here
}

distclean() {
    rm -rf "$PREFIX" && clean || true
}

dist() {
    local list=()

    IFS=' ' read -r -a list < <(rdepends "$@")

    build "$@" "${list[@]}"
}

# update libs_ver
update() {
    load "$1"

    slogi "update $1 $libs_ver => $2"
    sed "/libs_ver=/,/libs_build/s/$libs_ver/$2/g" -i "libs/$1.s" || sloge "update $1 failed"

    # load again and fetch
    fetch "$1" || sloge "update $1 => $2 failed"

    IFS=' ' read -r sha _ < <(sha256sum "$(_package_name "$libs_url")")
    sed "s/libs_sha=.*$/libs_sha=$sha/" -i "libs/$1.s"
}

_on_exit() {
    # show ccache statistics
    if test -z "$CCACHE_DISABLE"; then
        ccache -d "$CCACHE_DIR" -s
    fi

    rm -rf "$TEMPDIR"
}

TEMPDIR="$(mktemp -d)" && trap _on_exit EXIT

_init || exit 110

if [[ "$0" =~ libs.sh$ ]]; then
    cd "$(dirname "$0")" && "$@" || exit $?
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
