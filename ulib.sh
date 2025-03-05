#!/bin/bash -e
# shellcheck shell=bash

umask  0022
export LANG=C

# options
export ULOGS=${ULOGS:-tty}              # tty,plain,silent
export NJOBS=${NJOBS:-$(nproc)}

export UPKG_STRICT=${UPKG_STRICT:-1}    # check on file changes on ulib.sh
export UPKG_MIRROR=${UPKG_MIRROR:-}     # apply mirrors

export USE_CCACHE=${USE_CCACHE:-0}      # enable ccache or not

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

# ulogcmd <command>
ulogcmd() {
    ulogi "..Run" "$(tr -s ' ' <<< "$@")"
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
    [ -z "$ROOT" ] && ROOT="$(pwd -P)" || return 0

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

    export ROOT PREFIX WORKDIR

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
        MAKE:make
        CMAKE:cmake
        MESON:meson
        NINJA:ninja
        PKG_CONFIG:pkg-config
        PATCH:patch
        INSTALL:install
        CARGO:cargo
        GO:go
    )

    # MSYS2
    is_msys && progs+=(
        # we are using MSYS shell, but still setup mingw32-make
        MMAKE:mingw32-make.exe
        RC:windres.exe
    )
    for x in "${progs[@]}"; do
        IFS=':' read -r k v _ <<< "$x"

        p="$($which "$v" 2>/dev/null)"

        [ -n "$p" ] || {
            uloge "....." "missing host tools $v, abort"
            return 1
        }

        eval -- export "$k=$p"
    done

    # ccache
    if [ "$USE_CCACHE" -ne 0 ] && which ccache &>/dev/null; then
        CCACHE_DIR="$ROOT/.ccache"
        CCACHE_TEMPDIR="$ROOT/.ccache"
        CC="ccache $CC"
        CXX="ccache $CXX"
        export CC CXX CCACHE_DIR
    fi

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
            LDFLAGS="-L$PREFIX/lib -static"
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
    export MESON="$(tr -s ' ' <<< "$MESON")"

    # export again after cmake and others
    export PKG_CONFIG="$PKG_CONFIG --define-variable=prefix=$PREFIX --static"

    # setup go envs: don't modify GOPATH here
    export GOBIN="$PREFIX/bin"
    export GOMODCACHE="$ROOT/.go/pkg/mod"
    export GO111MODULE="auto"
    [ -z "$UPKG_MIRROR" ] || export GOPROXY="$UPKG_MIRROR/gomods"
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

configure() {
    [ -f configure ] || {
        if [ -f autogen.sh ]; then
            ulogcmd ./autogen.sh
        elif [ -f configure.ac ]; then
            ulogcmd autoreconf -i -f
        fi
    }

    local cmdline

    cmdline="./configure --prefix=$(_prefix)"

    # append user args
    cmdline+=" ${upkg_args[*]} $*"

    # suffix options, override user's
    cmdline=$(sed                       \
        -e 's/--enable-shared //g'      \
        -e 's/--disable-static //g'     \
        <<<"$cmdline")

    ulogcmd "$cmdline"
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

    # expand targets, as '.NOTPARALLEL' may not set for targets
    for x in "${targets[@]}"; do
        case "$x" in
            # deparallels for install target
            install)    cmdline="${cmdline//-j[0-9]*/-j1}"  ;;
            install/*)  cmdline="${cmdline//-j[0-9]*/-j1}"  ;;
        esac
        ulogcmd "$cmdline" "$x"
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
    is_msys && opts+=( -G"'MSYS Makefiles'" )

    # cmake
    ulogcmd $CMAKE "${opts[*]}" "${upkg_args[@]}" "$@"

}

meson() {
    local cmdline="$MESON"

    # append user args
    cmdline+=" $(_filter_targets "$@") ${MESON_ARGS[*]} $(_filter_options "$@")"

    ulogcmd "$cmdline"
}

ninja() {
    local cmdline="$NINJA"

    # append user args
    cmdline+=" $*"

    ulogcmd "$cmdline"
}

cargo() {
    local cmdline="$CARGO $* ${upkg_args[*]}"

    # cargo always download and rebuild targets
    if [ -n "$UPKG_MIRROR" ]; then
        cat << EOF >> .cargo/config.toml
[source.crates-io]
replace-with = 'mirrors'

[source.mirrors]
registry = "sparse+$UPKG_MIRROR/crates.io-index/"

[registries.mirrors]
index = "sparse+$UPKG_MIRROR/crates.io-index/"
EOF
    fi

    ulogcmd "$cmdline"
}

go() {
    local cmdline=("$GO")

    export CGO_ENABLED=0 # necessary for build static
    case "$1" in
        build)
            cmdline+=(build -x)

            #1. static without dwarf and stripped
            #2. add version info
            cmdline+=(-ldflags="'-w -s -extldflags=-static -X main.version=$upkg_ver-${upkg_rev:-0}'")

            cmdline+=("${@:2}")
            ;;
        *)
            cmdline+=("$@")
            ;;
    esac

    ulogcmd "${cmdline[@]}"
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

_pkglist() {
    echo "$PREFIX/packages.lst"
}

_pkginfo() {
    echo "$PREFIX/$upkg_name/pkginfo"
}

# _pack pkgname <file list>
_pack() {
    pushd "$PREFIX"

    # shellcheck disable=SC2001
    local files=("$(sed -e "s:$PREFIX::g" <<< "${@:2}")")

    local pkgname="$upkg_name/$1-$upkg_ver-${upkg_rev:-0}.tar.gz"
    local revision="$upkg_name/$1-$upkg_ver-${upkg_rev:-0}"

    mkdir -p "$(dirname "$pkgname")"
    tar -czvf "$pkgname" "${@:2}"

    mkdir -pv "$(dirname "$(_pkginfo)")"
    touch "$(_pkginfo)"
    sha256sum "$pkgname" >> "$(_pkginfo)"

    # create a revision file
    grep -Fw "$1" "$(_pkginfo)" > "$revision"

    # create a symlink
    ln -sfv "$revision" "$1-revision"

    popd
}

# cmdlet executable [name] [alias ...]
cmdlet() {
    ulogi ".Inst" "install cmdlet $1 => $2 (alias ${*:3})"

    # strip or not ?
    local args=(-v)
    file "$1" | grep -qFw 'not stripped' && args+=(-s)

    local pkgname="$1"
    local installed=()
    if [ $# -lt 2 ]; then
        "$INSTALL" "${args[@]}" -m755 "$1" "$(_prefix)/bin/" || return 1
        installed+=("bin/$(basename "$1")")
    else
        local pkgname="$2"
        "$INSTALL" "${args[@]}" -m755 "$1" "$(_prefix)/bin/$2" || return 1
        installed+=("bin/$2")

        if [ $# -gt 2 ]; then
            for x in "${@:3}"; do
                ln -sfv "$2" "$(_prefix)/bin/$x"
                installed+=("bin/$x")
            done
        fi
    fi

    _pack "$(basename "$pkgname")" "${installed[@]}" | _capture
}

# _fix_pc path/to/xxx.pc
_fix_pc() {
    local prefix=$(_prefix)
    if grep -qFw "$prefix" "$1"; then
        # shellcheck disable=SC2016
        sed -e 's!^prefix=.*$!prefix=\${PREFIX}!' \
            -e "s!$prefix!\${prefix}!g" \
            -i "$1"
    fi
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

    ulogi ".Libx" "install library $libname => (alias ${alias[*]})"
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
                _fix_pc "$1"
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

    _pack "$libname" "${installed[@]}" | _capture
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
    ulogi ".Appx" "$* => $APREFIX"

    # install the entrypoint
    $INSTALL -v -m755 "$@" "$APREFIX" || return 1

    local installed
    read -r -a installed <<< "$( find "$APREFIX" -type f | sed -e "s:^$PREFIX::" -e 's:^/::' | xargs )"

    _pack "$(basename "$1")" "${installed[@]}" | _capture
}

# _fetch <url> <sha256> [local]
_fetch() {
    local url=$1
    local sha=$2
    local zip=$3

    # to current dir
    [ -n "$zip" ] || zip="$(basename "$url")"

    #1. try local file first
    if [ -e "$zip" ]; then
        local x
        IFS=' ' read -r x _ <<<"$(sha256sum "$zip")"
        if [ "$x" = "$sha" ]; then
            ulogi ".Gotx" "$zip"
            return 0
        fi

        ulogw "Warn." "expected $sha, actual $x, broken?"
        rm "$zip"
    fi

    local args=(--fail -sL --progress-bar -o "$zip")
    mkdir -p "$(dirname "$zip")"

    #2. try mirror
    if [ -n "$UPKG_MIRROR" ] &&
        curl "${args[@]}" "$UPKG_MIRROR/packages/$(basename "$zip")" 2>/dev/null; then
        ulogi ".Getx" "$UPKG_MIRROR/packages/$(basename "$zip")"
    #3. try original
    elif curl "${args[@]}" "$url"; then
        ulogi ".Getx" "$url"
    else
        uloge "Error" "get $url failed."
        return 1
    fi
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
    local arg0=("--strip-components=$skip")

    if tar --version | grep -qFw "bsdtar"; then
        arg0=(--strip-components "$skip")
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
            while [ "$skip" -gt 0 ]; do
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
        ulogcmd "patch -p1 < $x"
    done
}

# _load library
_load() {
    unset upkg_name upkg_lic
    unset upkg_ver upkg_rev
    unset upkg_url upkg_sha
    unset upkg_zip upkg_zip_strip
    unset upkg_dep upkg_args upkg_type
    unset upkg_patch_url upkg_patch_zip upkg_patch_sha upkg_patch_strip

    [ -f "$1" ] && source "$1" || source "libs/$1.u"
}

__deps_get() {( _load "$1"; echo "${upkg_dep[@]}"; )}

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

# compile target
compile() {(
    # start subshell before source
    set -eo pipefail

    _init


    ulogi ".Load" "$1"
    _load "$1"

    [ "$upkg_type" = "PHONY" ] && return

    # check upkg_name
    [ -n "$upkg_name" ] || upkg_name="$(basename "${1%.u}")"

    # sanity check
    [ -n "$upkg_url" ] || uloge "Error" "missing upkg_url" || return 1
    [ -n "$upkg_sha" ] || uloge "Error" "missing upkg_sha" || return 2

    # set PREFIX for app
    [ "$upkg_type" = "app" ] && {
        APREFIX="$PREFIX/app/$upkg_name"
        mkdir -p "$APREFIX"
    }

    # clear
    rm -f "$(_pkginfo)" 2>/dev/null

    sed -i "/^$upkg_name.*$/d" "$(_pkglist)" 2>/dev/null || touch "$(_pkglist)"

    # prepare work dir
    mkdir -p "$PREFIX"
    mkdir -p "$(dirname "$(_logfile)")"

    local workdir="$WORKDIR/$upkg_name-$upkg_ver"

    # strict mode: clean before compile
    [ "$UPKG_STRICT" -eq 0 ] || rm -rf "$workdir"

    mkdir -p "$workdir" && cd "$workdir"

    echo -e "**** start build $upkg_name ****\n$(date)\n" > "$(_logfile)"

    ulogi ".Path" "$PWD"

    # build library
    _prepare && upkg_static || {
        tail -v "$(_logfile)"
        return 1
    }

    # append lib to packages.lst
    echo "$upkg_name $upkg_ver $upkg_lic" >> "$(_pkglist)"

    # record @ work dir
    touch "$WORKDIR/.$upkg_name"

    ulogi "<<<<<" "$upkg_name@$upkg_ver\n"
)}

# build targets and its dependencies
# build <lib list>
build() {
    _init || return $?

    touch "$(_pkglist)"

    # get full dep list before build
    local deps=()
    for dep in $(_deps_get "$1"); do
        #1. dep.u been updated
        #2. ulib.sh been updated (UPKG_STRICT)
        #3. dep been installed (skip)
        #4. dep not installed
        local nonexists_or_outdated=0
        if [ "$UPKG_STRICT" -ne 0 ] && [ -e "$WORKDIR/.$dep" ]; then
            if [ "$ROOT/libs/$dep.u" -nt "$WORKDIR/.$dep" ]; then
                nonexists_or_outdated=1
            elif [ "ulib.sh" -nt "$WORKDIR/.$dep" ]; then
                nonexists_or_outdated=1
            fi
        elif grep -w "^$dep" "$(_pkglist)" &>/dev/null; then
            continue
        else
            nonexists_or_outdated=1
        fi
        [ "$nonexists_or_outdated" -eq 0 ] || deps+=("$dep")
    done

    # pull dependencies
    local libs=()
    for dep in "${deps[@]}"; do
        ./cmdlets.sh package "$dep" || libs+=("$dep")
    done

    ulogi "Build" "$1 (${libs[*]})"
    libs+=("$1")

    local i=0
    for ulib in "${libs[@]}"; do
        i=$((i + 1))
        ulogi ">>>>>" "#$i/${#libs[@]} $ulib"

        compile "$ulib" || return 127
    done
}

search() {
    _init || return $?

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
    _init || return $?
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
