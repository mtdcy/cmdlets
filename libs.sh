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

ulogi() { _ulog info  "$@" >&2;             }
ulogw() { _ulog warn  "$@" >&2;             }
uloge() { _ulog error "$@" >&2; return 1;   }
ulogf() { _ulog error "$@" >&2; exit 1;     } # exit shell

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
        ulogf "Error" "$(cat "$PREFIX/.ERR_MSG" | xargs)"
    fi
}

_capture() {
    if [ "$CL_LOGGING" = "silent" ]; then
        cat >> "$(_logfile)"
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
        done < <(tee -a "$(_logfile)")

        tput ed                         # clear to end of screen
        tput smam                       # line break on
        tput sgr0                       # reset colors
    else
        tee -a "$(_logfile)"
    fi
}

echocmd() {
    {
        echo "$*"
        eval -- "$*"
    } 2>&1 | CL_LOGGING=${CL_LOGGING:-silent} _capture
}

# ulogcmd <command>
ulogcmd() {
    ulogi "..Run" "$(tr -s ' ' <<< "$*")"
    echocmd "$@"
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

_init_rust() {
    if which rustup &>/dev/null; then
        CARGO="$(rustup which cargo)"
        RUSTC="$(rustup which rustc)"
    else
        CARGO="$(which cargo)"
        RUSTC="$(which rustc)"
    fi

    if test -z "$CARGO"; then
        uloge "Init:" "rustup/cargo not exists"
    fi

    export CARGO RUSTC

    # cargo/rust
    CARGO_HOME="$ROOT/.cargo"
    CARGO_BUILD_JOBS="$CL_NJOBS"
    CARGO_BUILD_TARGET="$(uname -m)-unknown-linux-musl"

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
        #export RUSTUP_DIST_SERVER=$CL_MIRRORS/rust-static
        #export RUSTUP_UPDATE_ROOT=$CL_MIRRORS/rust-static/rustup
    fi
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

    # prepend PREFIX/bin to PATH
    PATH="$PREFIX/bin:$PATH"

    mkdir -p "$PREFIX"/{bin,include,lib{,/pkgconfig}} "$WORKDIR"

    true > "$PREFIX/.ERR_MSG" # create a zero sized file

    export ROOT PREFIX WORKDIR PATH

    # setup program envs
    local _find=which
    is_darwin && _find="xcrun --find" || true

    is_glibc || unset CL_TOOLCHAIN_PREFIX

    local k v p E progs

    # shellcheck disable=SC2054,SC2206
    progs=(
        CC:${CL_TOOLCHAIN_PREFIX}gcc
        CXX:${CL_TOOLCHAIN_PREFIX}g++
        AR:${CL_TOOLCHAIN_PREFIX}ar
        AS:${CL_TOOLCHAIN_PREFIX}as
        LD:${CL_TOOLCHAIN_PREFIX}ld
        NM:${CL_TOOLCHAIN_PREFIX}nm
        RANLIB:${CL_TOOLCHAIN_PREFIX}ranlib
        STRIP:${CL_TOOLCHAIN_PREFIX}strip
        MAKE:gmake,make
        CMAKE:cmake
        MESON:meson
        NINJA:ninja
        PKG_CONFIG:pkg-config
        PATCH:patch
        INSTALL:install
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

        [ -n "$p" ] || ulogw "Init:" "missing host tools ${v[*]}"

        eval export "$k=$p"
    done

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

        LDFLAGS="-L$PREFIX/lib -static"

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
        CCACHE_DIR="$WORKDIR/.ccache"
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

    # warnings only
    _init_go    || true
    _init_rust  || true

    # cmdlets
    [ -z "$CL_MIRRORS" ] || export CMDLETS_MAIN_REPO="$CL_MIRRORS/cmdlets/latest"
}

inspect_env() {
    env
}

apply_c89_flags() {
    local flags=(
        -Wno-error=implicit-int
        -Wno-error=incompatible-pointer-types
    )

    is_clang && flags+=(
        -Wno-error=implicit-function-declaration
    ) || flags+=(
        -Wno-implicit-function-declaration
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

    [[ "${cmdline[*]}" =~ \ V=[0-9]+ ]] || cmdline+=( V=1 )

    ulogcmd "${cmdline[@]}"
}

cmake() {
    # extend CC will break cmake build, set CMAKE_C_COMPILER_LAUNCHER instead
    export CC="${CC/ccache\ /}"
    export CXX="${CXX/ccache\ /}"
    # asm
    is_arm64 || {
        export CMAKE_ASM_NASM_COMPILER="$NASM"
        export CMAKE_ASM_YASM_COMPILER="$YASM"
    }
    # compatible
    if "$CMAKE" --version | grep -Fq 'version 4.'; then
        export CMAKE_POLICY_VERSION_MINIMUM=3.5
    fi
    # extend CC will break cmake build, set CMAKE_C_COMPILER_LAUNCHER instead
    if [ -z "$CCACHE_DISABLE" ]; then
        export CMAKE_C_COMPILER_LAUNCHER=ccache
        export CMAKE_CXX_COMPILER_LAUNCHER=ccache
    fi

    # extend CMAKE with compile tools
    local cmdline=(
        "$CMAKE"
        -DCMAKE_BUILD_TYPE=RelWithDebInfo
        -DCMAKE_INSTALL_PREFIX="'$PREFIX'"
        -DCMAKE_PREFIX_PATH="'$PREFIX'"
        -DCMAKE_MAKE_PROGRAM="'$MAKE'"
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
    # rust
    is_darwin || {
        export RUSTFLAGS="-C target-feature=+crt-static"
        export PKG_CONFIG_ALL_STATIC=true
        export LIBZ_SYS_STATIC=1
        export ZLIB_STATIC=1
    }

    local cmdline="$CARGO $* ${upkg_args[*]}"

    # cargo always download and rebuild targets
    case "$1" in
        build)
            is_darwin || cmdline+=" --target $(uname -m)-unknown-linux-musl"
            ;;
    esac

    ulogcmd "$cmdline"
}

_init_go() {
    GO="$(which go)"

    [ -n "$GO" ] || uloge "Init:" "missing host tool go"

    # setup go envs: don't modify GOPATH here
    export GOBIN="$PREFIX/bin"
    export GOMODCACHE="$ROOT/.go/pkg/mod"
    export GO111MODULE=auto

    # => go()
    unset CGO_ENABLED

    [ -z "$CL_MIRRORS" ] || export GOPROXY="$CL_MIRRORS/gomods"
}

# go can not amend `-ldflags='
_filter_go_ldflags() {
    local _ldflags=()
    while [ $# -gt 0 ]; do
        local args
        case "$1" in
            -ldflags=*)
                # use xargs to remove quotes
                IFS=' ' read -r -a args <<< "$(echo "${1#-ldflags=}" | xargs)"
                _ldflags+=( "${args[@]}" )
                ;;
            -ldflags)
                IFS=' ' read -r -a args <<< "$(echo "$2" | xargs)"
                _ldflags+=( "${args[@]}" )
                shift
                ;;
        esac
        shift
    done
    echo "${_ldflags[@]}"
}

_filter_go_options() {
    local _options=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -ldflags=*) ;;
            -ldflags)   shift ;;
            *)          _options+=( "$1" ) ;;
        esac
        shift
    done
    echo "${_options[@]}"
}

# shellcheck disable=SC2207
go() {
    export CGO_CFLAGS="$CFLAGS"
    export CGO_CXXFLAGS="$CXXFLAGS"
    export CGO_CPPFLAGS="$CPPFLAGS"
    export CGO_LDFLAGS="$LDFLAGS"

    # CGO_ENABLED=0 is necessary for build static binaries
    CGO_ENABLED="${CGO_ENABLED:-0}"

    local cmdline=("$GO" "$1" )
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

            # verbose
            cmdline+=( -x -v )

            #1. static without dwarf and stripped
            #2. add version info
            local ldflags=( -w -s -X main.version="$upkg_ver" )

            [ "$CGO_ENABLED" -ne 0 ] || ldflags+=( -extldflags=-static )

            # user ldflags
            ldflags+=( $(_filter_go_ldflags "${@:2}") )

            # set ldflags
            cmdline+=( -ldflags="'${ldflags[*]}'" )

            # append user options
            cmdline+=( $(_filter_go_options "${@:2}") )
            ;;
        *)
            cmdline+=( "${@:2}" )
            ;;
    esac

    ulogcmd CGO_ENABLED="$CGO_ENABLED" "${cmdline[@]}"
}

# easy command for go project
go_build() {
    go clean || true
    go build "$@"
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

TAR="$(which gtar 2>/dev/null || which tar)"

# _pkgfile name <file list>
_pkgfile() {
    pushd "$PREFIX"

    mkdir -pv "$upkg_name"

    # name contains version code?
    local name version
    IFS='@' read -r name version <<< "$1"

    test -n "$version" || version="$upkg_ver"

    # pkgfile with full version
    local pkgfile="$upkg_name/$name@$upkg_ver.tar.gz"
    local pkgvern="$upkg_name/$name@$upkg_ver"

    # pkginfo is shared by library() and cmdlet(), full versioned
    local pkginfo="$upkg_name/pkginfo@$upkg_ver"; touch "$pkginfo"

    local files

    # shellcheck disable=SC2001
    IFS=' ' read -r -a files <<< "$(sed -e "s%$PWD/%%g" <<< "${@:2}")"

    echocmd "$TAR" -czvf "$pkgfile" "${files[@]}"

    # there is a '*' when run sha256sum in msys
    #sha256sum "$pkgfile" >> "$pkginfo"
    IFS=' *' read -r sha _ <<< "$(sha256sum "$pkgfile")"
    echo "$sha $pkgfile" >> "$pkginfo"

    # create a version file
    grep -Fw "$pkgfile" "$pkginfo" > "$pkgvern"

    # v2/pkginfo
    _link "$pkgvern" "$upkg_name/$name@latest"
    _link "$pkginfo" "$upkg_name/pkginfo@latest"

    if [ "$version" != "$upkg_ver" ]; then
        _link "$pkgvern" "$upkg_name/$name@$version"
        _link "$pkginfo" "$upkg_name/pkginfo@$version"
    fi

    if [ "$version" != "$upkg_ver" ]; then
        _link "$upkg_name/$name@$version" "$name@$version"
    else
        _link "$upkg_name/$name@latest"   "$name@latest"
    fi

    # v3/manifest: name pkgfile sha
    touch "cmdlets.manifest"
    # clear full versioned records
    sed -i "\#^$name@\?[^\ ]\+ $upkg_name/.*@$upkg_ver\.#d" cmdlets.manifest
    # clear versioned records
    sed -i "\#^$1 $pkgfile #d" cmdlets.manifest
    # new records
    echo "$1 $pkgfile $sha" >> cmdlets.manifest

    popd
}

# find out which files are installed by `make install'
inspect_install() {
    find "$PREFIX" > "$upkg_name.pack.pre"

    ulogcmd "$@"

    find "$PREFIX" > "$upkg_name.pack.post"

    diff "$upkg_name.pack.post" "$upkg_name.pack.pre" | sed "s%$PREFIX%%g" > "$upkg_name.pack"
}

# cmdlet executable [name] [alias ...]
cmdlet() {
    ulogi ".Inst" "install cmdlet $1 => ${2:-$(basename "$1")} (alias ${*:3})"

    # strip or not ?
    local args=( -v )
    file "$1" | grep -qFw 'not stripped' && args+=( -s )

    local target="$PREFIX/bin/$(basename "${2:-$1}")"

    echocmd "$INSTALL" "${args[@]}" -m755 "$1" "$target" || return 1

    local alias=()
    for x in "${@:3}"; do
        _link "$target" "$PREFIX/bin/$x"
        alias+=( "$PREFIX/bin/$x" )
    done

    _pkgfile "$(basename "$target")" "$target" "${alias[@]}"
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

# install pkgfile
pkgfile() {
    if [ "$*" = "--help" ]; then
        cat << "EOF"
pkgfile name[:alias:...]            \
        [include]       header.h    \
        include/xxx     xxx.h       \
        [lib]           libxxx.a    \
        [lib/pkgconfig] xxx.pc      \
        share           yyy         \
        share/man       zzz
EOF
        return 0
    fi

    ulogi ".Inst" "pkgfile $*"

    local name alias subdir installed
    IFS=':' read -r name alias <<< "$1"
    shift # skip name and alias

    while [ $# -ne 0 ]; do
        local file

        file="$1"; shift
        case "$file" in
            # no libtool archive files
            # https://www.linuxfromscratch.org/blfs/view/svn/introduction/la-files.html
            *.la) ;;
            *.h|*.hxx|*.hpp)    [[ "$subdir" =~ ^include        ]] || subdir="include"      ;;
            *.a|*.so|*.so.*)    [[ "$subdir" =~ ^lib            ]] || subdir="lib"          ;;
            *.cmake)            [[ "$subdir" =~ ^lib/cmake      ]] || subdir="lib/cmake"    ;;
            *.pc)               [[ "$subdir" =~ ^lib/pkgconfig  ]] || subdir="lib/pkgconfig"
                _fix_pc "$file"
                ;;
            include*|lib*|bin*|share*)
                subdir="$file"
                echocmd "$INSTALL" -d -m755 "$PREFIX/$subdir"
                continue
                ;;
        esac

        local target symlink

        # install file to target
        target="$PREFIX/$subdir/$(basename "$file")"

        echocmd "$INSTALL" -m644 "$file" "$target" || return 1

        # override existing symlink?
        [[ "${installed[*]}" == *"$target"* ]] || installed+=( "$target" )

        # install alias(links)
        #1. match file name with pkg name
        #2. match file name with pkg name without lib prefix
        #  e.g: library libncursesw:libncurses:libcurses include/ncursesw.h

        for x in ${alias//:/ }; do
            if [[ "${file%.*}" =~ "$name"$ ]]; then
                symlink="$PREFIX/$subdir/$x.${file##*.}"
            elif [[ "${file%.*}" =~ "${name#lib}"$ ]]; then
                symlink="$PREFIX/$subdir/${x#lib}.${file##*.}"
            fi

            # no match
            test -n "$symlink" || continue

            # already installed?
            [[ "${installed[*]}" == *"$symlink"* ]] && continue

            _link "$target" "$symlink"

            installed+=( "$symlink" )
        done
    done

    _pkgfile "$name" "${installed[@]}"
}

# append lib prefix if not exists then call install()
library() {
    local libname="$1"

    [[ "$libname" =~ ^lib ]] || libname="lib$libname"

    pkgfile "$libname" "${@:2}"
}

# perform visual check on cmdlet
check() {
    ulogi "..Run" "check $*"

    local bin="$(which "$1")"
    [[ "$bin" =~ ^"$PREFIX" ]] || {
        ulogf "CHECK" "cann't find $1"
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
            ldd "$bin"
            ulogf "CHECK" "$bin is dynamically linked"
        } || true
    elif is_darwin; then
        otool -L "$bin" # | grep -v "libSystem.*"
    elif is_msys; then
        ntldd "$bin"
    else
        ulogw "FIXME: $OSTYPE"
    fi
}

CURL="$(which curl)"
CURL_OPTS=( --fail -vL )

# _curl source destination [options]
_curl() {
    local source="$1"
    local dest="${2:-/dev/null}"

    echocmd "$CURL" -I "${@:3}" "${CURL_OPTS[@]}" "$source" -o /dev/null &&
    echocmd "$CURL" -S "${@:3}" "${CURL_OPTS[@]}" "$source" -o "$dest"
}

# _curl_to_stdout source [options]
_curl_stdout() {
    echocmd "$CURL" -S "${@:2}" "${CURL_OPTS[@]}" "$1"
}

# fetch url to packages/ or return error
# _fetch <zip> <sha> <urls...>
_fetch() {
    local zip=$1
    local sha=$2
    local url=$3
    local _sha mirror

    mkdir -p "$(dirname "$zip")"

    #1. try local file first
    if [ -f "$zip" ]; then
        ulogi ".FILE" "$zip"
        IFS=' *' read -r _sha _ <<< "$(sha256sum "$zip")"
        if [ "$_sha" = "$sha" ]; then
            return 0
        else
            ulogw "..SHA" "$_sha vs $sha (expected)"
            rm -f "$zip"
        fi
    fi

    #2. try mirror
    if test -n "$CL_MIRRORS"; then
        mirror="$CL_MIRRORS/packages/$(basename "$zip")"
        ulogi ".CURL" "$mirror"
        _curl "$mirror" "$zip"
    fi

    #3. try originals
    if ! test -f "$zip"; then
        for url in "${@:3}"; do
            ulogi ".CURL" "$url"
            _curl "$url" "$zip" && break
        done
    fi

    if test -f "$zip"; then
        ulogi ".FILE" "$(sha256sum "$zip")"
        return 0
    else
        uloge ".CURL" "$* failed"
        return 1
    fi
}

# _fetch git_url#branch_or_tag_name [path]
_fetch_git() {
    local url branch

    ulogi "..GIT" "$1 => $2"

    IFS='#' read -r url branch <<< "$1"
    if test -d "${2%.git}/.git"; then
        true
    else
        git clone --depth=1 --recurse-submodules --branch "$branch" --single-branch "$url" "${2%.git}"
    fi
}

# show git tag > branch > commit
git_version() {
    git describe --tags --exact-match 2> /dev/null ||
    git symbolic-ref -q --short HEAD ||
    git rev-parse --short HEAD
}

# unzip file to current dir, or exit program
# _unzip <file> [strip]
_unzip() {
    ulogi ".Zipx" "$1 => $(pwd)"

    [ -r "$1" ] || ulogf ".Zipx" "$1 read failed, permission denied?"

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
    CL_LOGGING=silent echocmd "${cmd[@]}" "$1" || ulogf ".Zipx" "$1 failed."

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

# prepare source code or return error
_prepare() {
    if test -n "$upkg_git"; then
        _fetch_git "$upkg_git" . || return 1

        for submodule in "${upkg_git_submodules[@]}"; do
            _fetch_git "$submodule" "$(basename "${submodule%#*}")" || return 2
        done

        return 0
    else
        # use the first url to construct zip file name local zip="$ROOT/packages/$upkg_zip"
        local zip="$ROOT/packages/$upkg_zip"

        # download zip file
        _fetch "$zip" "$upkg_sha" "${upkg_url[@]}" || return 1
        # unzip to current fold
        _unzip "$zip" "$upkg_zip_strip" || return 2
    fi

    # patch urls
    if test -n "${upkg_patch_url[*]}"; then
        for i in "${!upkg_patch_url[@]}"; do
            local zip="$ROOT/packages/${upkg_patch_zip[i]:-$(basename "${upkg_patch_url[i]}")}"

            # download files
            _fetch "$zip" "${upkg_patch_sha[i]}" "${upkg_patch_url[i]}" || return 3
            # unzip to current fold
            _unzip "$zip" || return 4
        done
    fi

    # apply patches
    for patch in "${upkg_patches[@]}"; do
        case "$patch" in
            http://*|https://*)
                ulogi "..Run" "patch p1 -N < $patch"
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
    [ -n "$upkg_zip"  ] || upkg_zip="$(basename "$upkg_url")"

    [ "$upkg_type" = ".PHONY" ] && return 0

    # git
    [ -n "$upkg_git" ] && return 0

    # sanity checks: always exit program|subshell here
    if test -z "$upkg_url" || test -z "$upkg_sha"; then
        _on_failure "$upkg_name: missing upkg_url or upkg_sha"
    fi
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

    if test -z "$upkg_url" && test -z "$upkg_git"; then
        ulogw "<<<<<" "skip dummy target $upkg_name"
        return 0
    fi

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
        sleep 1 # let _capture() finish

        local logfile="$(_logfile)"
        mv "$logfile" "$logfile.fail"
        tail -v "$logfile.fail"
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
            #3. libs.sh been updated (CL_STRICT)
            if [ ! -e "$PREFIX/.$x.d" ] || [ "$ROOT/libs/$x.u" -nt "$PREFIX/.$x.d" ]; then
                deps+=( "$x" )
            #elif [ "$CL_STRICT" -ne 0 ] && [ "libs.sh" -nt "$PREFIX/.$x.d" ]; then
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

    CMDLETS_PREBUILTS=$PREFIX ./cmdlets.sh manifest &>/dev/null || true

    # pull dependencies
    local targets=()
    if [ "$CL_FORCE" -ne 0 ]; then
        ulogi "Force rebuild dependencies"
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
            ulogf "Error" "build ${targets[i]} failed"
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

    _fetch "$ROOT/packages/$upkg_zip" "$upkg_sha" "$upkg_url"
}

arch() {
    basename "$PREFIX"
}

# zip files for release actions
zip_files() {
    # manifest
    cd "$PREFIX" && "$TAR" -cvf "cmdlets.manifest.tar.gz" cmdlets.manifest && cd - || true

    # log files
    local logs="${PREFIX/prebuilts/logs}"
    test -d "$logs" || return 0
    test -n "$(ls -A "$logs")" || return 0
    "$TAR" -C "$logs" -cvf "$logs-logs.tar.gz" .
}

_init || exit 110

if [[ "$0" =~ libs.sh$ ]]; then
    "$@"
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
