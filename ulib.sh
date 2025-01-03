#!/bin/bash
# shellcheck shell=bash

umask  0022
export LANG=C

# options
export UPKG_STRICT=${UPKG_STRICT:-1}    # check on file changes on ulib.sh
export UPKG_CHECKS=${UPKG_CHECKS:-1}    # enable check/tests
export UPKG_MIRROR=${UPKG_MIRROR:-http://pub.mtdcy.top/packages}
export UPKG_REPO=${UPKG_REPO:-http://pub.mtdcy.top/cmdlets/latest}

export ULOGS=${ULOGS:-tty}          # tty,plain,silent
export NJOBS=${NJOBS:-$(nproc)}

# clear envs => setup by _init
unset ROOT PREFIX WORKDIR

# conditionals
is_darwin() { [[ "$OSTYPE" =~ darwin ]];                            }
is_msys()   { [[ "$OSTYPE" =~ msys ]];                              }
is_linux()  { [[ "$OSTYPE" =~ linux ]];                             }
is_glibc()  { ldd --version 2>&1 | grep -qFi "glibc";               }
# 'ldd --version' in alpine always return 1
is_musl()   { { ldd --version 2>&1 || true; } | grep -qF "musl";    }
is_clang()  { $CC --version 2>/dev/null | grep -qF "clang";         }

# ulog [error|info|warn] "leading" "message"
_ulog() {
    local lvl date message

    [ $# -gt 1 ] && lvl="$(tr 'A-Z' 'a-z' <<< "$1")"
    date="$(date '+%m-%d %H:%M:%S')"

    # https://github.com/yonchu/shell-color-pallet/blob/master/color16
    case "$lvl" in
        "error")
            shift 1
            message="[$date] \\033[31m$1\\033[39m ${*:2}"
            ;;
        "info")
            shift 1
            message="[$date] \\033[32m$1\\033[39m ${*:2}"
            ;;
        "warn")
            shift 1
            message="[$date] \\033[33m$1\\033[39m ${*:2}"
            ;;
        *)
            message="[$date] \\033[32m$1\\033[39m ${*:2}"
            ;;
    esac
    echo -e "$message"
}

ulogi() { _ulog info  "$@";             }
ulogw() { _ulog warn  "$@";             }
uloge() { _ulog error "$@"; return 1;   }

_logfile() {
    echo "${PREFIX/prebuilts/logs}/$upkg_name.log"
}

# | _capture
_capture() {
    if [ "$ULOGS" = "tty" ] && test -t 1 && which tput &>/dev/null; then
        # tput: DON'T combine caps, not universal.
        local head endl i
        head=$(tput hpa 0)
        endl=$(tput el)
        i=0
        tput rmam       # line break off
        tput dim        # half bright mode => not always work
        tee -a "$(_logfile)" | while read -r line; do
            printf '%s' "${head}#$i: ${line//$'\n'/}${endl}"
            i=$((i + 1))
        done
        tput hpa 0 el   # clear line
        tput smam       # line break on
        tput sgr0       # reset
    elif [ "$ULOGS" = "plain" ]; then
        tee -a "$(_logfile)"
    else
        cat >> "$(_logfile)"
    fi
}

# command <command>
command() {
    ulogi "..Run" "$@"
    eval -- "$*" 2>&1 | _capture
}

echocmd() {
    echo "$*"
    eval -- "$*"
}

_prefix() {
    [ "$upkg_type" = "app" ] && echo "$APREFIX" || echo "$PREFIX"
}

_filter_options() {
    local opts;
    while [ $# -gt 0 ]; do
        # -j1
        [[ "$1" =~ ^-j[0-9]+$ ]] && opts+=" $1" && shift && continue || true
        case "$1" in
            *=*)    opts+=" $1";    shift   ;;
            -*)     opts+=" $1 $2"; shift 2 ;;
            *)      shift ;;
        esac
    done
    echo "$opts"
}

_filter_targets() {
    local tgts;
    while [ $# -gt 0 ]; do
        [[ "$1" =~ ^-j[0-9]+$ ]] && shift && continue || true
        case "$1" in
            *=*)    shift   ;;
            -*)     shift 2 ;;
            *)      tgts+=" $1"; shift ;;
        esac
    done
    echo "$tgts"
}

# TODO: add support for toolchain define
_init() {
    [ -z "$ROOT" ] || return 0

    # internal envs
    ROOT="$(pwd -P)"

    local arch
    case "$OSTYPE" in
        darwin*)    arch="$(uname -m)-apple-darwin"         ;;
        msys*)      arch="$(uname -m)-$OSTYPE-${MSYSTEM,,}" ;;
        *)          arch="$(uname -m)-$OSTYPE"              ;;
    esac

    PREFIX="$ROOT/prebuilts/$arch"
    mkdir -p "$PREFIX"/{bin,include,lib{,/pkgconfig}}

    WORKDIR="$ROOT/out/$arch"
    mkdir -p "$WORKDIR"

    # ccache
    CCACHE_DIR="$ROOT/.ccache"

    export ROOT PREFIX WORKDIR CCACHE_DIR

    # setup program envs
    local which=which
    is_darwin && which="xcrun --find" || true

    local k v p E progs
    progs=(
        CC:gcc
        CXX:g++
        AR:ar
        AS:as
        LD:ld
        NM:nm
        RANLIB:ranlib
        STRIP:strip
        NASM:nasm
        YASM:yasm
        CMAKE:cmake
        MESON:meson
        NINJA:ninja
        PKG_CONFIG:pkg-config
        PATCH:patch
        INSTALL:install
    )
    is_msys && progs+=( MAKE:mingw32-make ) || progs+=( MAKE:make )
    is_msys && E=".exe"
    for x in "${progs[@]}"; do
        IFS=':' read -r k v _ <<< "$x"

        p="$($which "$v" 2>/dev/null)" ||
        p="$($which "$v$E" 2>/dev/null)"

        eval -- export "$k=$p"
    done

    if test -n "$DISTCC_HOSTS"; then
        if which distcc &>/dev/null; then
            ulogi "....." "apply distcc settings"
            CC="distcc"
            #CXX="distcc" # => cause c++ build failed.

            export NJOBS=$((NJOBS * $(wc -w <<< "$DISTCC_HOSTS")))
        fi
    fi

    # common flags for c/c++
    local FLAGS=(
        -g -O3              # debug with O3
        -fPIC -DPIC         # PIC
    )
    is_msys || FLAGS+=(
        -ffunction-sections #
    )
    # Notes:
    #   1. some libs may fail with '-fdata-sections'
    #   2. some test may fail with '-DNDEBUG'

    #export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib -Wl,-gc-sections"

    # macOS does not support statically linked binaries
    if is_darwin; then
        LDFLAGS="-L$PREFIX/lib -Wl,-dead_strip"
    else
        FLAGS+=( --static ) # static linking => two '--' vs ldflags
        if is_msys; then
            LDFLAGS="-L$PREFIX/lib"
        elif is_clang; then
            LDFLAGS="-L$PREFIX/lib -Wl,-dead_strip -static"
        else
            LDFLAGS="-L$PREFIX/lib -Wl,-gc-sections -static"
        fi
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

    # meson
    # builti options: https://mesonbuild.com/Builtin-options.html
    #  libdir: some package prefer install to lib/<machine>/
    MESON_ARGS="                                    \
        -Dprefix=$PREFIX                            \
        -Dlibdir=lib                                \
        -Dbuildtype=release                         \
        -Ddefault_library=static                    \
        -Dpkg_config_path=$PKG_CONFIG_PATH          \
    "
        #-Dprefer_static=true                        \

    # remove spaces
    export MESON="$(sed -e 's/ \+/ /g' <<<"$MESON")"

    # export again after cmake and others
    export PKG_CONFIG="$PKG_CONFIG --define-variable=prefix=$PREFIX --static"

    # global common args for configure
    local _UPKG_ARG0=(
        --prefix="$PREFIX"
        --disable-option-checking
        --enable-silent-rules
        --disable-dependency-tracking

        # static
        --disable-shared
        --enable-static

        # no nls & rpath for single static cmdlet.
        --disable-nls
        --disable-rpath
    )

    # remove spaces
    export UPKG_ARG0="${_UPKG_ARG0[*]}"
}

dynamicalize() {
    CFLAGS="${CFLAGS//--static/}"
    CXXFLAGS="${CXXFLAGS//--static/}"
    LDFLAGS="${LDFLAGS//-static/}"

    export CFLAGS CXXFLAGS LDFLAGS
}

deparallelize() {
    export NJOBS=1
}

# cleanup arguments ...
cleanup() {
    # deprecated
    true
}

configure() {
    local cmdline

    cmdline="./configure --prefix=$(_prefix)"

    # append user args
    cmdline+=" ${upkg_args[*]} $*"

    # suffix options, override user's
    cmdline=$(sed                       \
        -e 's/--enable-shared //g'      \
        -e 's/--disable-static //g'     \
        <<<"$cmdline")

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    command "$cmdline"
}

make() {
    local cmdline="$MAKE"
    local targets=()

    cmdline+=" $(_filter_options "$@")"
    IFS=' ' read -r -a targets <<< "$(_filter_targets "$@")"

    # default target
    [ -z "${targets[*]}" ] && targets=(all)

    # set default njobs
    [[ "$cmdline" =~ -j[0-9\ ]* ]] || cmdline+=" -j$NJOBS"

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    # expand targets, as '.NOTPARALLEL' may not set for targets
    for x in "${targets[@]}"; do
        case "$x" in
            # deparallels for install target
            install)    cmdline="${cmdline//-j[0-9]*/-j1}"  ;;
            install/*)  cmdline="${cmdline//-j[0-9]*/-j1}"  ;;
        esac
        command "$cmdline" "$x"
    done
}

cmake() {
    local opts=()

    # only apply '-static' to EXE_LINKER_FLAGS
    CFLAGS="${CFLAGS//\ --static/}"
    CXXFLAGS="${CXXFLAGS//\ --static/}"
    LDFLAGS="${LDFLAGS//\ -static/}"

    opts+=(
        -DCMAKE_BUILD_TYPE=RelWithDebInfo
        -DCMAKE_INSTALL_PREFIX="$(_prefix)"
        -DCMAKE_PREFIX_PATH="$PREFIX"
        -DCMAKE_C_FLAGS="'$CFLAGS'"
        -DCMAKE_CXX_FLAGS="'$CXXFLAGS'"
        -DCMAKE_EXE_LINKER_FLAGS="'$LDFLAGS'"
        #-DCMAKE_C_COMPILER="$CC"
        #-DCMAKE_CXX_COMPILER="$CXX"
        #-DCMAKE_AR="$AR"
        #-DCMAKE_LINKER="$LD"
        #-DCMAKE_MAKE_PROGRAM="$MAKE"
        -DCMAKE_ASM_NASM_COMPILER="$NASM"
        -DCMAKE_ASM_YASM_COMPILER="$YASM"
    )

    # link static executable
    is_darwin || [[ "${upkg_args[*]}" =~ CMAKE_EXE_LINKER_FLAGS ]] || opts+=(
        -DCMAKE_EXE_LINKER_FLAGS="'$LDFLAGS -static'"
    )

    # cmake using a mixed path style with MSYS Makefiles, why???
    is_msys && opts+=( -G"MSYS Makefiles" )

    # cmake
    command $CMAKE "${opts[*]}" "${upkg_args[@]}" "$@"

}

meson() {
    local cmdline="$MESON"

    # append user args
    cmdline+=" $(_filter_targets "$@") ${MESON_ARGS[*]} $(_filter_options "$@")"

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    command "$cmdline"
}

ninja() {
    local cmdline="$NINJA"

    # append user args
    cmdline+=" $*"

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    command "$cmdline"
}

install() {
    if [[ "$*" =~ \s- ]]; then
        echocmd "$*"
    else
        # install include xxx.h ...
        # install lib libxxx.a ...
        "$INSTALL" -v -m644 "${@:2}" "$(_prefix)/$1"
    fi
}

# cmdlet executable name [alias ...]
cmdlet() {
    ulogi "..Bin" "install cmdlet $1 => $2 (alias ${*:3})"
    # strip or not ?
    local args=(-v)
    file "$1" | grep -qFw 'not stripped' && args+=(-s)

    if [ $# -lt 2 ]; then
        "$INSTALL" "${args[@]}" -m755 "$1" "$(_prefix)/bin/" || return 1
    else
        "$INSTALL" "${args[@]}" -m755 "$1" "$(_prefix)/bin/$2" || return 1
        if [ $# -gt 2 ]; then
            for x in "${@:3}"; do
                ln -sfv "$2" "$(_prefix)/bin/$x"
            done
        fi
    fi | _capture

}

# _library file subdir [libname] [alias]
#  => return installed files and links if alias exists
_install() {
    $INSTALL -m644 "$1" "$(_prefix)/$2" || return 1

    local installed=("$2/$(basename "$1")")
    if [ -n "$4" ]; then # install with alias
        if [[ "$1" =~ $3.${1##*.}$ ]]; then
            for alias in "${@:4}"; do
                ln -sf "$(basename "$1")" "$(_prefix)/$2/$alias.${1##*.}"
                installed+=("$2/$alias.${1##*.}")
            done
        elif [[ "$1" =~ ${3#lib}.${1##*.}$ ]]; then
            for alias in "${@:4}"; do
                ln -sf "$(basename "$1")" "$(_prefix)/$2/${alias#lib}.${1##*.}"
                installed+=("$2/${alias#lib}.${1##*.}")
            done
        fi
    fi
    echo "${installed[@]}"
}

# library   name:alias1:alias2          \
#           include/xxx     xxx.h       \
#           lib             libxxx.a    \
#           lib/pkgconfig   libxxx.pc
library() {
    local libname alias subdir installed
    IFS=':' read -r libname alias <<< "$1"
    IFS=':' read -r -a alias <<< "$alias"
    shift # skip libname and alias

    ulogi "..Lib" "install library $libname => (alias ${alias[*]})"
    while [ $# -ne 0 ]; do
        case "$1" in
            *.h)
                [[ "$subdir" =~ ^include ]] || subdir="include"
                installed+=("$(_install "$1" "$subdir" "$libname" "${alias[@]}")") || return 1
                ;;
            *.a|*.la|*.so|*.so.*)
                [[ "$subdir" =~ ^lib ]] || subdir="lib"
                installed+=("$(_install "$1" "$subdir" "$libname" "${alias[@]}")") || return 1
                ;;
            *.pc)
                [[ "$subdir" =~ ^lib\/pkgconfig ]] || subdir="lib/pkgconfig"
                installed+=("$(_install "$1" "$subdir" "$libname" "${alias[@]}")") || return 1
                ;;
            include*|lib*|bin*)
                subdir="$1"
                mkdir -pv "$(_prefix)/$subdir"
                ;;
            *)
                uloge "Error" "unknown library options $1"
                return 1
                ;;
        esac
        shift
    done

    {
        local revision="$libname-revision"

        pushd "$PREFIX"

        # pollute revision file
        echocmd curl --fail -sL -o "$revision" \
            "$UPKG_REPO/$(basename "$PREFIX")/$libname-revision" ||
        touch "$revision"

        # append version and revision
        libname+="-$upkg_ver"
        [ -z "$upkg_rev" ] || libname+="-$upkg_rev"
        libname+=".tar.gz"

        echocmd tar -cvzf "$libname" "${installed[@]}"

        sed -i "/$libname/d" "$revision"

        sha256sum "$libname" >> "$revision"

        cat "$revision"

        popd
    } | _capture
}

# _fix_pc path/to/xxx.pc
_fix_pc() {
    local prefix=$(_prefix)
    if grep -qFw "$prefix" "$1"; then
        sed -e 's!^prefix=.*$!prefix=\${PREFIX}!' \
            -e "s!$prefix!\${prefix}!g" \
            -i "$1"
    fi
}

# perform quick check with cmdlet version
# version /path/to/cmdlet [--version]
# version cmdlet [--version]
version() {
    # deprecated
    true
}

# perform visual check on cmdlet
check() {
    ulogi "..Run" "check $*"

    local bin="$1"
    if [ -e "$(_prefix)/bin/$1" ]; then
        bin="$(_prefix)/bin/$1"
    fi

    # print to tty instead of capture it
    file "$bin"

    # check version if options/arguments provide
    if [ $# -gt 1 ]; then
        echocmd "$bin" "${@:2}" 2>&1 | grep -Fw "$upkg_ver"
    fi

    # check linked libraries
    if is_linux; then
        file "$bin" | grep -Fw "dynamically linked" && {
            ulogw "....." "$bin is dynamically linked"
            echocmd ldd "$bin"
        } || true
    elif is_darwin; then
        echocmd otool -L "$bin" # | grep -v "libSystem.*"
    elif is_msys; then
        echocmd ntldd "$bin"
    else
        uloge "FIXME: $OSTYPE"
    fi
}

# applet <name>
applet() {
    local pkgname revision
    # install the entrypoint
    $INSTALL -v -m755 "$@" "$APREFIX" || return 1

    {
        revision="$upkg_name-revision"

        pushd "$APREFIX"

        # pollute revision file
        echocmd curl --fail -sL -o "$revision" \
            "$UPKG_REPO/$(basename "$PREFIX")/app/$revision" ||
        touch "$revision"

        # pkgname
        pkgname="$upkg_name-$upkg_ver"
        [ -z "$upkg_rev" ] || pkgname+="-$upkg_rev"
        pkgname+=".tar.gz"

        # make a package
        touch "$pkgname"
        tar -czf "$pkgname" --exclude="$pkgname" --exclude="$revision" .

        sed -i "/$pkgname/d" "$revision"

        # record package
        sha256sum "$pkgname" >> "$revision"

        cat "$revision"

        popd
    } | _capture
}

# env: UPKG_MIRROR
# _fetch <url> <sha256> [local]
_fetch() {
    local url=$1
    local sha=$2
    local zip=$3

    # to current dir
    [ -n "$zip" ] || zip="$(basename "$url")"

    ulogi ".Getx" "$url"

    #1. try local file first
    if [ -e "$zip" ]; then
        local x
        IFS=' ' read -r x _ <<<"$(sha256sum "$zip")"
        [ "$x" = "$sha" ] && ulogi "..Got" "$zip" && return 0

        ulogw "Warn." "expected $sha, actual $x, broken?"
        rm "$zip"
    fi

    local args=(--fail -L --progress-bar -o "$zip")
    mkdir -p "$(dirname "$zip")"

    #2. try mirror
    curl "${args[@]}" "$UPKG_MIRROR/$(basename "$zip")" 2>/dev/null ||
    #3. try original
    curl "${args[@]}" "$url" || {
        uloge "Error" "get $url failed."
        return 1
    }
    ulogi "..Got" "$(sha256sum "$zip" | cut -d' ' -f1)"
}

# _unzip <file> [strip]
#  => unzip to current dir
_unzip() {
    ulogi ".Zipx" "$1 >> $(pwd)"

    [ -r "$1" ] || {
        uloge "Error" "open $1 failed."
        return 1
    }

    # skip leading directories, default 1
    local skip=${2:-1}
    local arg0=(--strip-components=$skip)

    if tar --version | grep -qFw "bsdtar"; then
        arg0=(--strip-components $skip)
    fi
    # XXX: bsdtar --strip-components fails with some files like *.tar.xz
    #  ==> install gnu-tar with brew on macOS

    case "$1" in
        *.tar.lz)   tar "${arg0[@]}" --lzip -xvf "$1"   ;;
        *.tar.bz2)  tar "${arg0[@]}" -xvjf "$1"         ;;
        *.tar.gz)   tar "${arg0[@]}" -xvzf "$1"         ;;
        *.tar.xz)   tar "${arg0[@]}" -xvJf "$1"         ;;
        *.tar)      tar "${arg0[@]}" -xvf "$1"          ;;
        *.tbz2)     tar "${arg0[@]}" -xvjf "$1"         ;;
        *.tgz)      tar "${arg0[@]}" -xvzf "$1"         ;;
        *)
            rm -rf * &>/dev/null  # see notes below
            case "$1" in
                *.rar)  unrar x "$1"                    ;;
                *.zip)  unzip -o "$1"                   ;;
                *.7z)   7z x "$1"                       ;;
                *.bz2)  bunzip2 "$1"                    ;;
                *.gz)   gunzip "$1"                     ;;
                *.Z)    uncompress "$1"                 ;;
                *)      false                           ;;
            esac &&

            # universal skip method, faults:
            #  #1. have to clear dir before extraction.
            #  #2. will fail with bad upkg_zip_strip.
            while [ $skip -gt 0 ]; do
                mv -f */* . || true
                skip=$((skip - 1))
            done &&
            find . -type d -empty -delete || true
            ;;
    esac 2>&1 | ULOGS=silent _capture
}

# prepare package sources and patches
_prepare() {
    # check upkg_zip
    [ -n "$upkg_zip" ] || upkg_zip="$(basename "$upkg_url")"
    upkg_zip="$ROOT/packages/${upkg_zip##*/}"

    # check upkg_zip_strip, default: 1
    upkg_zip_strip=${upkg_zip_strip:-1}

    # check upkg_patch_*
    if [ -n "$upkg_patch_url" ]; then
        [ -n "$upkg_patch_zip" ] || upkg_patch_zip="$(basename "$upkg_patch_url")"
        upkg_patch_zip="$ROOT/packages/${upkg_patch_zip##*/}"

        upkg_patch_strip=${upkg_patch_strip:-0}
    fi

    # download files
    _fetch "$upkg_url" "$upkg_sha" "$upkg_zip" || return $?

    # unzip to current fold
    _unzip "$upkg_zip" "$upkg_zip_strip" || return $?

    # patches
    if [ -n "$upkg_patch_url" ]; then
        # download patches
        _fetch "$upkg_patch_url" "$upkg_patch_sha" "$upkg_patch_zip"

        # unzip patches into current dir
        _unzip "$upkg_patch_zip" "$upkg_patch_strip"
    fi

    # apply patches
    mkdir -p patches
    for x in "${upkg_patches[@]}"; do
        # url(sha)
        if [[ "$x" =~ ^http* ]]; then
            IFS='()' read -r a b _ <<< "$x"

            # download to patches/
            "$a" "$b" "patches/$(basename "$a")"

            x="patches/$a"
        fi

        # apply patch
        command "patch -p1 < $x"
    done
}

# _load library
_load() {
    unset upkg_name upkg_lic
    unset upkg_ver upkg_rev
    unset upkg_url upkg_zip
    unset upkg_dep upkg_args
    [ -f "$1" ] && source "$1" || source "libs/$1.u"
}

__deps_get() {
    ( _load "$1"; echo "${upkg_dep[@]}"; )
}

# _deps_get libname
_deps_get() {
    local leaf deps
    IFS=' ' read -r -a deps <<< "$(__deps_get "$1")"

    while [ "${#deps[@]}" -ne 0 ]; do
        local _deps meet
        IFS=' ' read -r -a _deps <<< "$(__deps_get "${deps[0]}")"

        if [ ${#_deps[@]} -ne 0 ]; then
            meet=1
            for x in "${_deps[@]}"; do
                [[ "${leaf[*]}" =~ $x ]] || {
                    # prepend to deps and continue the while loop
                    deps=("${_deps[@]}" "${deps[@]}")
                    meet=0
                    break
                }
            done
            [ "$meet" -eq 1 ] || continue
        fi

        # leaf lib or all deps are meet.
        [[ "${leaf[*]}" =~ ${deps[0]} ]] || leaf+=("${deps[0]}")
        deps=("${deps[@]:1}")
    done
    echo "${leaf[@]}"
}

# compile <lib list>
#  => auto build deps
compile() {
    _init

    touch "$PREFIX/packages.lst"

    # get full dep list before build
    local libs=()
    for lib in "$@"; do
        local deps=($(_deps_get "$lib"))

        # find unmeets.
        local unmeets=()
        for x in "${deps[@]}"; do
            #1. x.u been updated
            #2. ulib.sh been updated (UPKG_STRICT)
            #3. x been installed (skip)
            #4. x not installed
            if [ "$UPKG_STRICT" -ne 0 ] && [ -e "$WORKDIR/.$x" ]; then
                if [ "$ROOT/libs/$x.u" -nt "$WORKDIR/.$x" ]; then
                    unmeets+=($x)
                elif [ "ulib.sh" -nt "$WORKDIR/.$x" ]; then
                    unmeets+=($x)
                fi
            elif grep -w "^$x" $PREFIX/packages.lst &>/dev/null; then
                continue
            else
                unmeets+=($x)
            fi
        done

        # does x exists in list?
        for x in "${unmeets[@]}"; do
            grep -Fw "$x" <<<"${libs[@]}" &>/dev/null || libs+=($x)
        done

        # append the lib to list.
        libs+=($lib)
    done

    ulogi "Build" "$* (${libs[*]})"

    local i=0
    for ulib in "${libs[@]}"; do
        i=$((i + 1))

        (   # start subshell before source
            set -eo pipefail
            ulogi ">>>>>" "#$i/${#libs[@]} $ulib"

            ulogi ".Load" "$ulib.u"

            # shellcheck source=libs/zlib.u
            _load "$ulib"

            [ "$upkg_type" = "PHONY" ] && return

            # check upkg_name
            [ -n "$upkg_name" ] || upkg_name="$ulib"

            # sanity check
            [ -n "$upkg_url" ] || uloge "Error" "missing upkg_url" || return 1
            [ -n "$upkg_sha" ] || uloge "Error" "missing upkg_sha" || return 2

            # set PREFIX for app
            [ "$upkg_type" = "app" ] && APREFIX="$PREFIX/app/$upkg_name"

            # prepare work dir
            mkdir -p "$PREFIX"
            mkdir -p "$(dirname "$(_logfile)")"

            local workdir="$WORKDIR/$ulib-$upkg_ver"
            [ "$UPKG_STRICT" -eq 0 ] || rm -rf "$workdir"
            mkdir -p "$workdir" && cd "$workdir"

            echo -e "**** start build $ulib ****\n$(date)\n" > "$(_logfile)"

            ulogi ".Path" "$PWD"

            # delete lib from packages.lst before build
            sed -i "/^$ulib.*$/d" "$PREFIX/packages.lst"

            # build library
            _prepare && upkg_static &&

            # append lib to packages.lst
            echo "$ulib $upkg_ver $upkg_lic" >> "$PREFIX/packages.lst" &&

            # record @ work dir
            touch "$WORKDIR/.$ulib" &&

            ulogi "<<<<<" "$ulib@$upkg_ver\n" || {
                uloge "Error" "build $ulib failed.\n" || true
                tail -v "$(_logfile)"
                return 127
            }
        ) || return $?
    done # End for
}

search() {
    _init

    ulogi "Search $PREFIX"
    for x in "$@"; do
        # binaries ?
        ulogi "Search binaries ..."
        find "$PREFIX/bin" -name "$x*" 2>/dev/null  | sed "s%^$ROOT/%%"

        # libraries?
        ulogi "Search libraries ..."
        find "$PREFIX/lib" -name "$x*" -o -name "lib$x*" 2>/dev/null  | sed "s%^$ROOT/%%"

        # headers?
        ulogi "Search headers ..."
        find "$PREFIX/include" -name "$x*" -o -name "lib$x*" 2>/dev/null  | sed "s%^$ROOT/%%"

        # pkg-config?
        ulogi "Search pkgconfig ..."
        if $PKG_CONFIG --exists "$x"; then
            ulogi ".Found $x @ $($PKG_CONFIG --modversion "$x")"
            echo "PREFIX : $($PKG_CONFIG --variable=prefix "$x")"
            echo "CFLAGS : $($PKG_CONFIG --static --cflags "$x" )"
            echo "LDFLAGS: $($PKG_CONFIG --static --libs "$x"   )"
            # TODO: add a sanity check here
        fi

        x=lib$x
        if $PKG_CONFIG --exists "$x"; then
            ulogi ".Found $x @ $($PKG_CONFIG --modversion "$x")"
            echo "PREFIX : $($PKG_CONFIG --variable=prefix "$x" )"
            echo "CFLAGS : $($PKG_CONFIG --static --cflags "$x" )"
            echo "LDFLAGS: $($PKG_CONFIG --static --libs "$x"   )"
            # TODO: add a sanity check here
        fi
    done
}

# load libname
load() {
    _init
    _load "$1"
}

# fetch libname
fetch() {
    load "$1"

    [ -n "$upkg_zip" ] || upkg_zip="$(basename "$upkg_url")"

    _fetch "$upkg_url" "$upkg_sha" "$ROOT/packages/$upkg_zip"
}

if [[ "$0" =~ ulib.sh$ ]]; then
    "$@"
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
