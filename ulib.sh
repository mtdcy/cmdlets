#!/bin/bash -e
# shellcheck shell=bash

umask  0022
export LANG=C

# options
export CL_FORCE=${CL_FORCE:-0}          # force rebuild all dependencies
export CL_LOGGING=${CL_LOGGING:-tty}    # tty,plain,silent
export CL_STRICT=${CL_STRICT:-1}        # check on file changes on ulib.sh
export CL_MIRRORS=${CL_MIRRORS:-}       # package mirrors, and go/cargo/etc
export CL_CCACHE=${CL_CCACHE:-0}        # enable ccache or not
export CL_NJOBS=${CL_NJOBS:-1}          # noparallel by default

# clear envs => setup by _init
unset ROOT PREFIX WORKDIR

# conditionals
is_darwin() { [[ "$OSTYPE" =~ darwin ]];                            }
is_msys()   { [[ "$OSTYPE" =~ msys ]] || test -n "$MSYSTEM";        }
is_linux()  { [[ "$OSTYPE" =~ linux ]];                             }
is_glibc()  { ldd --version 2>&1 | grep -qFi "glibc";               }
# 'ldd --version' in alpine always return 1
is_musl()   { { ldd --version 2>&1 || true; } | grep -qF "musl";    }
is_clang()  { $CC --version 2>/dev/null | grep -qF "clang";         }
is_arm64()  { uname -m | grep -q "arm64\|aarch64";                  }

# ulog [error|info|warn] "leading" "message"
_ulog() {
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

ulogi() { _ulog info  "$@";             }
ulogw() { _ulog warn  "$@";             }
uloge() { _ulog error "$@"; exit 1;     } # exit shell

_logfile() {
    echo "${PREFIX/prebuilts/logs}/$upkg_name.log"
}

# for subshell
# write error message to .ERR_MSG on failure
_on_failure() {
    echo "$*" >> "$PREFIX/.ERR_MSG"
    exit 1 # exit subshell
}

# for main shell
_exit_on_failure() {
    if test -s "$PREFIX/.ERR_MSG"; then
        uloge "Error" "$(cat "$PREFIX/.ERR_MSG" | xargs)"
    fi
}

_capture() {
    if [ "$CL_LOGGING" = "silent" ]; then
        cat >> "$(_logfile)"
    elif [ "$CL_LOGGING" = "tty" ] && test -t 1 && which tput &>/dev/null; then
        # tput: DON'T combine caps, not universal.
        local CL i

        CL="$(tput hpa 0)$(tput el)"

        i=0
        tput rmam       # line break off
        tput dim        # dim on
        tee -a "$(_logfile)" | while read -r line; do
            printf '%s' "$CL#$i: $line"
            i=$((i + 1))
        done
        echo -en "$CL"  # clear line
        tput smam       # line break on
        tput sgr0       # reset
    else
        tee -a "$(_logfile)"
    fi
}

echocmd() {
    {
        echo "$*"
        eval -- "$*"
    } 2>&1 | _capture
} 

# ulogcmd <command>
ulogcmd() {
    ulogi "..Run" "$(tr -s ' ' <<< "$*")"
    echocmd "$@"
}

CURL="$(which curl)"
CURL_OPTS=( --fail -L --max-redirs -1 --progress-bar --no-progress-meter )

# _curl source destination [options]
_curl() {
    local source="$1"
    local dest="${2:-/dev/null}"

    echocmd "$CURL" -sI "${@:3}" "${CURL_OPTS[@]}" "$source" -o /dev/null &&
    echocmd "$CURL" -vS "${@:3}" "${CURL_OPTS[@]}" "$source" -o "$dest"   
}

# _curl_to_stdout source [options]
_curl_stdout() {
    echocmd "$CURL" -vS "${@:2}" "${CURL_OPTS[@]}" "$1"
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
    if [ "$(uname -s)" = Darwin ]; then
        arch="$(uname -m)-apple-darwin"
    elif test -n "$MSYSTEM"; then
        arch="$(uname -m)-msys-${MSYSTEM,,}"
    elif ldd --version 2>/dev/null | grep -qFw musl; then
        arch="$(uname -m)-linux-musl"
    else
        arch="$(uname -m)-$OSTYPE"
    fi

    # prepare directories and files
    PREFIX="$ROOT/prebuilts/$arch"
    WORKDIR="$ROOT/out/$arch"

    # prepend PREFIX/bin to PATH
    PATH="$PREFIX/bin:$PATH"

    mkdir -p "$PREFIX"/{bin,include,lib{,/pkgconfig}} "$WORKDIR"

    true > "$PREFIX/.ERR_MSG" # create a zero sized file

    export ROOT PREFIX WORKDIR PATH

    # setup program envs
    local _find=which
    is_darwin && _find="xcrun --find" || true

    local k v p E progs

    # shellcheck disable=SC2054
    progs=(
        CC:gcc
        CXX:g++
        AR:ar
        AS:as
        LD:ld
        NM:nm
        RANLIB:ranlib
        STRIP:strip
        MAKE:gmake,make
        CMAKE:cmake
        MESON:meson
        NINJA:ninja
        PKG_CONFIG:pkg-config
        PATCH:patch
        INSTALL:install
        RUSTC:rustc
        CARGO:cargo
        GO:go
    )
    is_arm64 || progs+=(
        NASM:nasm
        YASM:yasm
    )

    # MSYS2
    is_msys && progs+=(
        # we are using MSYS shell, but still setup mingw32-make
        MMAKE:mingw32-make.exe
        RC:windres.exe
    )
    for x in "${progs[@]}"; do
        IFS=':' read -r k v <<< "$x"
        IFS=',' read -r -a v <<< "$v"

        for y in "${v[@]}"; do
            p="$($_find "$y" 2>/dev/null)" && break
        done

        [ -n "$p" ] || ulogw "....." "missing host tools ${v[*]}"

        eval export "$k=$p"
    done

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

    is_clang && FLAGS+=( 
        -Wno-error=deprecated-non-prototype 
    ) || true

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

    # export again after cmake and others
    export PKG_CONFIG="$PKG_CONFIG --define-variable=PREFIX=$PREFIX --static"

    # extend CMAKE with compile tools
    CMAKE=(
        "$CMAKE"
        -DCMAKE_C_COMPILER="$CC"
        -DCMAKE_CXX_COMPILER="$CXX"
        -DCMAKE_AR="$AR"
        -DCMAKE_LINKER="$LD"
        -DCMAKE_MAKE_PROGRAM="$MAKE"
    )
    is_arm64 || CMAKE+=(
        -DCMAKE_ASM_NASM_COMPILER="$NASM"
        -DCMAKE_ASM_YASM_COMPILER="$YASM"
    )
    if "$CMAKE" --version | grep -Fq 'version 4.'; then
        CMAKE+=( -DCMAKE_POLICY_VERSION_MINIMUM=3.5 )
    fi
    export CMAKE="${CMAKE[*]}"

    # ccache
    if [ "$CL_CCACHE" -ne 0 ] && which ccache &>/dev/null; then
        CC="ccache $CC"
        CXX="ccache $CXX"
        CCACHE_DIR="$PREFIX/.ccache"
        export CC CXX CCACHE_DIR

        # extend CC will break cmake build, set CMAKE_C_COMPILER_LAUNCHER instead
        export CMAKE_C_COMPILER_LAUNCHER=ccache
        export CMAKE_CXX_COMPILER_LAUNCHER=ccache
    else
        export CCACHE_DISABLE=1
    fi

    # setup go envs: don't modify GOPATH here
    export GOBIN="$PREFIX/bin"
    export GOMODCACHE="$ROOT/.go/pkg/mod"
    export GO111MODULE=on # go modules on
    export CGO_CFLAGS="$CFLAGS"
    export CGO_CXXFLAGS="$CXXFLAGS"
    export CGO_CPPFLAGS="$CPPFLAGS"
    export CGO_LDFLAGS="$LDFLAGS"
    unset CGO_ENABLED # => go()
    [ -z "$CL_MIRRORS" ] || export GOPROXY="$CL_MIRRORS/gomods"

    # cargo/rust
    CARGO_HOME="$ROOT/.cargo"
    CARGO_BUILD_JOBS="$CL_NJOBS"

    mkdir -p "$CARGO_HOME"

    export CARGO_HOME CARGO_BUILD_JOBS

    if [ -n "$CL_MIRRORS" ]; then
        # cargo
        local registry ver
        IFS='.' read -r _ ver _ < <("$CARGO" --version | grep -oE '[0-9\.]+')
        # cargo <= 1.68
        [ "$ver" -le 68 ] && registry="$CL_MIRRORS" || registry="sparse+$CL_MIRRORS"
        cat << EOF > "$CARGO_HOME/config.toml"
[source.crates-io]
replace-with = 'crates-io-mirrors'

[source.crates-io-mirrors]
registry = "$registry/crates.io-index/"
EOF
        # rust
        export RUSTUP_DIST_SERVER=$CL_MIRRORS/rust-static
        export RUSTUP_UPDATE_ROOT=$CL_MIRRORS/rust-static/rustup
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

inspect_env() {
    env
}

dynamicalize() {
    CFLAGS="${CFLAGS//--static/}"
    CXXFLAGS="${CXXFLAGS//--static/}"
    LDFLAGS="${LDFLAGS//-static/}"

    export CFLAGS CXXFLAGS LDFLAGS
}

dynamically_if_glibc() {
    is_glibc || return 0

    CFLAGS="${CFLAGS//--static/}"
    CXXFLAGS="${CXXFLAGS//--static/}"
    LDFLAGS="${LDFLAGS//-static/}"

    export CFLAGS CXXFLAGS LDFLAGS
}

apply_c89_flags() {
    local flags=(
        -Wno-error=implicit-function-declaration
        -Wno-error=implicit-int 
        -Wno-error=incompatible-pointer-types
    )

    is_clang && flags+=(
        -Wno-error=deprecated-non-prototype 
    )

    export CFLAGS+=" ${flags[*]}"
}

deparallelize() {
    export CL_NJOBS=1
}

configure() {
    if ! test -f configure; then
        if test -f autogen.sh; then
            ulogcmd ./autogen.sh
        elif test -f bootstrap; then
            ulogcmd ./bootstrap
        elif test -f configure.ac; then
            ulogcmd autoreconf -fis
        fi
    fi

    local cmdline

    cmdline="./configure --prefix=$PREFIX"

    # append user args
    cmdline+=" ${upkg_args[*]} $*"

    # suffix options, override user's
    cmdline=$(sed                       \
        -e 's/ --enable-shared//g'      \
        -e 's/ --disable-static//g'     \
        <<<"$cmdline")

    ulogcmd "$cmdline"
}

make() {
    local cmdline=( "$MAKE" "$@" )

    # set default njobs
    [[ "${cmdline[*]}" =~ -j[0-9\ ]* ]] || cmdline+=( -j"$CL_NJOBS" )

    ulogcmd "${cmdline[@]}"
}

cmake() {
    # only apply '-static' to EXE_LINKER_FLAGS only
    export LDFLAGS="${LDFLAGS//\ -static/}"

    local cmdline=( 
        "$CMAKE"
        -DCMAKE_BUILD_TYPE=RelWithDebInfo
        -DCMAKE_INSTALL_PREFIX="$PREFIX"
        -DCMAKE_PREFIX_PATH="$PREFIX"
        -DCMAKE_C_FLAGS="'${CFLAGS//--static/}'"
        -DCMAKE_CXX_FLAGS="'${CXXFLAGS//--static/}'"
    )

    # link static executable
    is_darwin || cmdline+=(
        -DCMAKE_EXE_LINKER_FLAGS="'$LDFLAGS -static'"
    )

    # cmake using a mixed path style with MSYS Makefiles, why???
    is_msys && cmdline+=( -G"'MSYS Makefiles'" )

    # append user args
    cmdline+=( "${upkg_args[@]}" "$@" )

    # cmake
    ulogcmd "${cmdline[@]}"
}

meson() {
    local cmdline=( "$MESON" "$(_filter_targets "$@")" )

    # meson
    # builtin options: https://mesonbuild.com/Builtin-options.html
    #  libdir: some package prefer install to lib/<machine>/
    cmdline+=(                              
        -Dprefix="'$PREFIX'"
        -Dlibdir=lib
        -Dbuildtype=release
        -Ddefault_library=static
        -Dpkg_config_path="'$PKG_CONFIG_PATH'"
    )

    ## meson >= 0.37.0
    #IFS='.' read -r _ ver _ < <($MESON --version)
    #[ "$ver" -lt 37 ] || cmdline+=( -Dprefer_static=true )

    # append user args
    cmdline+=( "${upkg_args[@]}" "$(_filter_options "$@")" )

    ulogcmd "${cmdline[@]}"
}

ninja() {
    local cmdline

    # append user args
    cmdline="$NINJA -j $CL_NJOBS -v $*"

    ulogcmd "$cmdline"
}

cargo() {
    local cmdline="$CARGO $* ${upkg_args[*]}"

    # cargo always download and rebuild targets

    ulogcmd "$cmdline"
}

go() {
    local cmdline=("$GO")

    case "$1" in
        build)
            # fix 'invalid go version'
            if [ -f go.mod ]; then
                local m n
                IFS="." read -r m n _ <<< "$("$GO" version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')"
                sed "s/^go [0-9.]\+$/go $m.$n/" -i go.mod
                # go mod edit won't work here
                #ulogcmd "$GO" mod edit -go="$m.$n"
                ulogcmd "$GO" mod tidy
            fi

            cmdline+=(build -x)

            #1. static without dwarf and stripped
            #2. add version info
            cmdline+=(-ldflags="'-w -s -extldflags=-static -X main.version=$upkg_ver'")

            cmdline+=("${@:2}")
            ;;
        *)
            cmdline+=("$@")
            ;;
    esac

    # CGO_ENABLED=0 is necessary for build static binaries
    ulogcmd CGO_ENABLED="${CGO_ENABLED:-0}" "${cmdline[@]}"
}

# easy command for go project
go_build() {
    go clean || true
    go build . 
}

# link source target 
_link() {
    #echo "link: $1 => $2" >&2
    if is_msys; then
        cp "$1" "$2"
    else
        ln -srf "$1" "$2"
    fi
}

TAR="$(which gtar 2>/dev/null || which tar)"

# _pack name <file list>
_pack() {
    pushd "$PREFIX"

    mkdir -pv "$upkg_name"

    # name contains version code?
    local name version
    IFS='@' read -r name version <<< "$1"

    local pkgname="$upkg_name/$name@$upkg_ver.tar.gz"
    local pkgvern="$upkg_name/$name@$upkg_ver"
    local pkginfo="$upkg_name/pkginfo@$upkg_ver"

    local files

    # shellcheck disable=SC2001
    IFS=' ' read -r -a files <<< "$(sed -e "s%$PWD/%%g" <<< "${@:2}")"

    echocmd "$TAR" -czvf "$pkgname" "${files[@]}"

    # pkginfo is shared by library() and cmdlet(), full versioned
    touch "$pkginfo" 

    # there is a '*' when run sha256sum in msys
    #sha256sum "$pkgname" >> "$pkginfo"
    IFS=' *' read -r sha _ <<< "$(sha256sum "$pkgname")"
    echo "$sha $pkgname" >> "$pkginfo"

    # create a version file
    grep -Fw "$pkgname" "$pkginfo" > "$pkgvern"

    # v2/pkginfo
    _link "$pkginfo" "$upkg_name/pkginfo@latest"
    _link "$pkgvern" "$upkg_name/$name@latest"

    if test -n "$version"; then
        _link "$upkg_name/$name@latest" "$name@$version"
    else
        _link "$upkg_name/$name@latest" "$name@latest"
    fi

    # v3/manifest: name pkgname sha
    touch cmdlets.manifest
    # only clear records of the corresponding version 
    sed "\#^$name.*$upkg_ver#d" -i cmdlets.manifest
    # new records
    echo "$1 $pkgname $sha" >> cmdlets.manifest

    popd
}

# find out which files are installed by `make install'
inspect_install() {
    find "$PREFIX" > "$upkg_name.pack.pre"

    ulogcmd "$@"
    
    find "$PREFIX" > "$upkg_name.pack.post"

    diff "$upkg_name.pack.post" "$upkg_name.pack.pre" > "$upkg_name.pack"
}

# cmdlet executable [name] [alias ...]
cmdlet() {
    ulogi ".Inst" "install cmdlet $1 => ${2:-$1} (alias ${*:3})"

    # strip or not ?
    local args=(-v)
    file "$1" | grep -qFw 'not stripped' && args+=(-s)

    local target

    target="$PREFIX/bin/$(basename "${2:-$1}")"

    # shellcheck disable=SC2154
    "$INSTALL" "${args[@]}" -m755 "$1" "$target" || return 1

    local links=()
    for x in "${@:3}"; do
        _link "$target" "$PREFIX/bin/$x"
        links+=( "$PREFIX/bin/$x" )
    done

    _pack "$(basename "$target")" "$target" "${links[@]}"
}

# _fix_pc path/to/xxx.pc
_fix_pc() {
    if grep -qFw "$PREFIX" "$1"; then
        # shellcheck disable=SC2016
        sed -e 's%^prefix=.*$%prefix=\${PREFIX}%' \
            -e "s%$PREFIX%\${prefix}%g" \
            -i "$1"
    fi
}

# _library file subdir [libname] [alias]
#  => return installed files and links if alias exists
_install() {
    local target syml

    target="$PREFIX/$2/$(basename "$1")"

    $INSTALL -m644 "$1" "$target" || return 1

    local installed=( "$target" )
        
    # install with alias
    if [ $# -ge 4 ]; then
        if [[ "$1" =~ $3.${1##*.}$ ]]; then
            for alias in "${@:4}"; do
                syml="$(dirname "$target")/$alias.${1##*.}"
                _link "$target" "$syml"
                installed+=( "$syml" )
            done
        elif [[ "$1" =~ ${3#lib}.${1##*.}$ ]]; then
            for alias in "${@:4}"; do
                syml="$(dirname "$target")/${alias#lib}.${1##*.}"
                _link "$target" "$syml"
                installed+=( "$syml" )
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
    local libname libalias subdir installed
    IFS=':' read -r libname libalias <<< "$1"
    IFS=':' read -r -a libalias <<< "$libalias"
    shift # skip libname and libalias

    [[ "$libname" =~ ^lib ]] || libname="lib$libname"

    ulogi ".Libx" "install library $libname => (alias ${libalias[*]})"
    while [ $# -ne 0 ]; do
        case "$1" in
            *.la)
                # no libtool archive files
                # https://www.linuxfromscratch.org/blfs/view/svn/introduction/la-files.html
                ;;
            *.h|*.hxx|*.hpp)
                [[ "$subdir" =~ ^include ]] || subdir="include"
                installed+=("$(_install "$1" "$subdir" "$libname" "${libalias[@]}")") || return 1
                ;;
            *.a|*.so|*.so.*)
                [[ "$subdir" =~ ^lib ]] || subdir="lib"
                installed+=("$(_install "$1" "$subdir" "$libname" "${libalias[@]}")") || return 1
                ;;
            *.pc)
                [[ "$subdir" =~ ^lib\/pkgconfig ]] || subdir="lib/pkgconfig"
                _fix_pc "$1"
                installed+=("$(_install "$1" "$subdir" "$libname" "${libalias[@]}")") || return 1
                ;;
            include*|lib*|bin*|share*)
                subdir="$1"
                mkdir -pv "$PREFIX/$subdir"
                ;;
            *)
                installed+=("$(_install "$1" "$subdir" "$libname" "${libalias[@]}")") || return 1
                ;;
        esac
        shift
    done

    _pack "$libname" "${installed[@]}"
}

# perform visual check on cmdlet
check() {
    ulogi "..Run" "check $*"

    local bin="$(which "$1")"
    [[ "$bin" =~ ^"$PREFIX" ]] || {
        uloge "....." "cann't find $1"
    }

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

# _fetch <url> <sha256> <zip>
_fetch() {
    local url=$1
    local sha=$2
    local zip=$3
    local _sha mirror

    #1. try local file first
    if [ -e "$zip" ]; then
        IFS=' *' read -r _sha _ <<< "$(sha256sum "$zip")"
        if [ "$_sha" = "$sha" ]; then
            ulogi ".FILE" "$zip"
            return 0
        fi

        ulogw ".Warn" "expected $sha but got $_sha"
        rm "$zip"
    fi

    mkdir -p "$(dirname "$zip")"

    #2. try mirror
    if test -n "$CL_MIRRORS"; then
        mirror="$CL_MIRRORS/packages/$(basename "$zip")"
        ulogi ".CURL" "$mirror"
        _curl "$mirror" "$zip" && return 0
    fi

    #3. try original
    ulogi ".CURL" "$url"
    _curl "$url" "$zip" && return 0

    uloge ".CURL" "Failed curl $url."
}

# _unzip <file> [strip]
#  => unzip to current dir
_unzip() {
    ulogi ".Zipx" "$1 >> $(pwd)"

    [ -r "$1" ] || {
        uloge "Error" "open $1 failed."
    }

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

    echocmd "${cmd[@]}" "$1" || return 1

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

# prepare package sources and patches
_prepare() {
    for i in "${!upkg_url[@]}"; do
        local zip="${upkg_zip[i]:-$(basename "${upkg_url[i]}")}"

        # to packages
        zip="$ROOT/packages/$zip"

        # download files
        _fetch "${upkg_url[i]}" "${upkg_sha[i]}" "$zip" || return $?
    
        # unzip to current fold
        _unzip "$zip" "${upkg_zip_strip[i]}" || return $?
    done

    pwd -P

    # apply patches
    for patch in "${upkg_patches[@]}"; do
        case "$patch" in
            http://|https://)
                ulogi "..Run" "patch -p1 -N < $patch"
                _curl_stdout "$patch" | patch -p1 -N
                ;;
            *)
                ulogcmd "patch -p1 -N < $patch"
                ;;
        esac
    done
}

# _load library
_load() {
    unset "${!upkg_@}"

    [ -f "$1" ] && source "$1" || source "libs/$1.u"

    # default values:
    [ -n "$upkg_name" ] || upkg_name="$(basename "${1%.u}")"
    [ -z "$upkg_zip"  ] || upkg_zip="$(basename "$upkg_url")"

    [ "$upkg_type" = ".PHONY" ] && return 0

    # sanity checks: always exit program|subshell here
    [ -n "$upkg_url" ] || exit 127
    [ -n "$upkg_sha" ] || exit 127
}

_load_deps() {( _load "$1"; echo "${upkg_dep[@]}"; )}

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

# compile target
compile() {(
    # start subshell before source
    set -eo pipefail

    ulogi ".Load" "$1"
    _load "$1"

    [ -n "$upkg_url" ] || {
        ulogw "<<<<<" "skip dummy target $upkg_name"
        return 0
    }

    # clear
    find "$PREFIX/$upkg_name" -name "pkginfo*" -exec rm -f {} \; 2>/dev/null || true

    # prepare work dir
    mkdir -p "$PREFIX"
    mkdir -p "$(dirname "$(_logfile)")"

    local workdir="$WORKDIR/$upkg_name-$upkg_ver"

    # strict mode: clean before compile
    [ "$CL_STRICT" -eq 0 ] || rm -rf "$workdir"

    mkdir -p "$workdir" && cd "$workdir"

    echo -e "**** start build $upkg_name ****\n$(date)\n" > "$(_logfile)"

    ulogi ".Path" "$PWD"

    # build library
    _prepare && upkg_static || {
        local logfile="$(_logfile)"
        tail -v "$logfile"
        mv "$logfile" "$logfile.fail"
        exit 127
    }

    # update tracking file
    touch "$PREFIX/.$upkg_name.d"

    ulogi "<<<<<" "$upkg_name@$upkg_ver"
)}

# check dependencies for libraries
_check_deps() {
    local deps=()

    for ulib in "$@"; do
        IFS=' ' read -r -a _deps <<< "$(_deps_get "$ulib")"

        for x in "${_deps[@]}"; do
            # already exists?
            [[ "${deps[*]}" == *"$x"* ]] && continue

            #1. dep not installed
            #2. dep.u been updated
            #3. ulib.sh been updated (CL_STRICT)
            if [ ! -e "$PREFIX/.$x.d" ] || [ "$ROOT/libs/$x.u" -nt "$PREFIX/.$x.d" ]; then
                deps+=( "$x" )
            #elif [ "$CL_STRICT" -ne 0 ] && [ "ulib.sh" -nt "$PREFIX/.$x.d" ]; then
            #    deps+=( "$x" )
            fi
        done
    done

    [ "${#deps[@]}" -gt 1 ] && _sort_by_depends "${deps[@]}" || echo "${deps[@]}"
}

# build targets and its dependencies
# build <lib list>
build() {
    ulogi "$*"

    IFS=' ' read -r -a deps <<< "$(_check_deps "$@")"

    _exit_on_failure

    ulogi "dependencies: ${deps[*]}"

    CMDLETS_PREBUILTS=$PREFIX ./cmdlets.sh menifest &>/dev/null || true

    # pull dependencies
    local targets=()
    if [ "$CL_FORCE" -ne 0 ]; then
        ulogi "-----" "Force rebuild dependencies"
        targets=( "${deps[@]}" )
    else
        CMDLETS_PREBUILTS=$PREFIX ./cmdlets.sh package "${deps[@]}"

        for dep in "${deps[@]}"; do
            [ -e "$PREFIX/.$dep.d" ] || targets+=( "$dep" )
        done
    fi

    # append targets
    targets+=( "$@" )

    if [ "${#targets[@]}" -gt 1 ]; then
        IFS=' ' read -r -a targets <<< "$(_sort_by_depends "${targets[@]}")"
    fi

    _exit_on_failure

    ulogi "Build" "${targets[*]}"

    for i in "${!targets[@]}"; do
        ulogi ">>>>>" "#$((i+1))/${#targets[@]} ${targets[i]}"

        time compile "${targets[i]}" || {
            uloge "Error" "build ${targets[i]} failed"
        }
    done
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

search() {
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
    _load "$1"
}

# fetch libname
fetch() {
    _load "$1"

    [ -n "$upkg_zip" ] || upkg_zip="$(basename "$upkg_url")"

    _fetch "$upkg_url" "$upkg_sha" "$ROOT/packages/$upkg_zip"
}

arch() {
    basename "$PREFIX"
}

# save log files to root/logs.tar.gz
zip_logfiles() {
    # zip log directory if not empty
    local target="${PREFIX/prebuilts/logs}"
    test -z "$(ls -A "$target")" || "$TAR" -C "$target" -cvf "$target-logs.tar.gz" .
}

_init || exit 110

if [[ "$0" =~ ulib.sh$ ]]; then
    "$@"
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
