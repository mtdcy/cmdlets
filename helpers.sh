#!/bin/bash
#
# helpers for build static libraries
#
# this file be loaded when compile targets
#
# warning: variable not assigned
# shellcheck disable=SC2154

# show git tag > branch > commit
git.version() {
    git describe --tags --exact-match 2> /dev/null ||
    git symbolic-ref -q --short HEAD ||
    git rev-parse --short HEAD
}

# 2026-02-06T21:05:01
date.iso8601() {
    date +%Y-%m-%dT%H:%M:%S
}

deparallelize() {
    export _NJOBS=1
}

libs.depends() {
    eval -- "$*" || { unset libs_dep libs_args libs_build; }
}

# find samples by name
samples() {
    find "$_ROOT_/samples" -type f -name "$*" | xargs
}

# locate executable in workdir
_locate_exe() {
    if test -f "$1"; then
        echo "$1"
    elif [[ ! "$1" =~ $_BINEXT$ ]]; then
        echo "$1$_BINEXT"
    fi
}

# locate executable in workdir or PREFIX
_locate_bin() {
    local bin="$(_locate_exe "$1")"
    test -f "$bin" && echo "$bin" || _locate_exe "$PREFIX/bin/$1"
}

_cflags_for_c89() {
    local flags=()

    if is_clang; then
        flags+=(
            -Wno-int-conversion
            -Wno-implicit-int
            -Wno-incompatible-pointer-types
            -Wno-implicit-function-declaration
        )
    else
        flags+=(
            -Wno-error=int-conversion
            -Wno-error=implicit-int
            -Wno-error=incompatible-pointer-types
            -Wno-error=implicit-function-declaration
        )
    fi

    echo "${flags[@]}"
}

libs.requires() {
    declare -a cflags cxxflags cppflags

    local x y
    for x in "$@"; do
        case "$x" in
            -std=c++*|-std=gnu++*)
                cxxflags+=( "$x" )
                ;;
            -std=*)
                cflags+=( "$x" )
                case "$x" in
                    -std=c89|-std=ansi|-std=gnu89)
                        cflags+=( $(_cflags_for_c89) )
                        ;;
                esac
                ;;
            -l*|-L*|-pthread|-Wl,*)
                ldflags+=( "$x" )
                ;;
            -I*)
                cppflags+=( "$x" )
                ;;
            -*)
                cflags+=( "$x" )
                cxxflags+=( "$x" )
                ;;
            *)
                "$PKG_CONFIG" --exists "$x" || die "$x not found."

                for y in $($PKG_CONFIG --cflags "$x"); do
                    case "$y" in
                        -std=c++*|-std=gnu++*)  cxxflags+=( "$y" )  ;;
                        -fpermissive)           cxxflags+=( "$y" )  ;;
                        *)                      cflags+=( "$y" )    ;;
                    esac
                done

                LDFLAGS+=" $($PKG_CONFIG --libs-only-l "$x")"
                ;;
        esac
    done

    CFLAGS+=" ${cflags[*]}"
    CXXFLAGS+=" ${cflags[*]} ${cxxflags[*]}"
    CPPFLAGS+=" ${cppflags[*]}"

    export CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
}

# return 0 if $1 >= $2
_version_ge() { [ "$(printf '%s\n' "$@" | sort -V | tail -n1)" = "$1" ]; }
_version_le() { [ "$(printf '%s\n' "$@" | sort -V | head -n1)" = "$1" ]; }

version.ge()  { _version_ge "$libs_ver" "$1";                            }
version.le()  { _version_le "$libs_ver" "$1";                            }

bootstrap() {
    if test -f autogen.sh; then
        slogcmd ./autogen.sh    || die "autogen.sh failed."
    elif test -f bootstrap; then
        slogcmd ./bootstrap     || die "bootstrap failed."
    elif test -f configure.ac; then
        slogcmd autoreconf -fiv || die "autoreconf failed."
    fi
}

# invoke just before configure or xxx.setup
# shellcheck disable=SC2016
_setup() {
    # env for xxx-config
    if test -x "$PREFIX/bin/krb5-config"; then
        export KRB5_CONFIG="$PREFIX/bin/krb5-config"
    fi

    if test -x "$PREFIX/bin/xml2-config"; then
        export XML2_CONFIG="$PREFIX/bin/xml2-config"
    fi

    if test -x "$PREFIX/bin/pcre2-config"; then
        export PCRE_CONFIG="$PREFIX/bin/pcre2-config"
    fi

    if test -f configure; then
        sed -i configure                            \
            -e 's/\<pkg-config\>/\$PKG_CONFIG/g'    \
            -e 's/\$PKGCONFIG/\$PKG_CONFIG/g'       \
            || die "setup configure failed."
        #1. replace pkg-config with PKG_CONFIG env
        #2. replace PKGCONFIG with PKG_CONFIG

        # apply PCRE_CONFIG if pcre2-config been used directly
        if grep -Fwq pcre2-config configure && ! grep -Fwq PCRE_CONFIG configure; then
            #1. $(pcre2-config --cflags-posix) => ngrep
            #2. `pcre2-config --cflags-posix`
            sed -i configure                                                        \
                -e '/\$(.*\<pcre2-config\>.*)/s/\<pcre2-config\>/\$PCRE_CONFIG/g'   \
                -e '/`.*\<pcre2-config\>.*`/s/\<pcre2-config\>/\$PCRE_CONFIG/g'     \
                || die "setup configure failed."
        fi
    fi
}

# shellcheck disable=SC2128
configure() {
    _setup

    local cmd

    test -f configure && cmd="./configure" || cmd="../configure"

    test -f "$cmd" || { bootstrap && cmd="./configure"; }

    test -f "$cmd" || die "configure not found."

    local args=( "${libs_args[@]}" "$@" )

    list_has args "--prefix=.*" || args+=( --prefix="$PREFIX" )

    if is_xbuild; then
        # some libraries use --target instead of --host, e.g: libvpx
        { "$cmd" --help || true; } | grep -q -- "--host=" && args+=( --host="$_TARGET" ) || true
    fi

    slogcmd "$cmd" "${args[@]}" || die "configure $libs_name failed."
}

make() {
    local cmdline=( "$MAKE" "$@" )

    # set default njobs
    [[ "${cmdline[*]}" =~ -j[0-9\ ]* ]] || cmdline+=( -j"$_NJOBS" )

    [[ "${cmdline[*]}" =~ \ V=[0-9]+ ]] || cmdline+=( V=1 )

    slogcmd "${cmdline[@]}" || die "make $libs_name failed."
}

make.all() {
    slogcmd "$MAKE" all "-j$_NJOBS" V=1 "$@" || die "make.all $libs_name failed."
}

make.install() {
    slogcmd "$MAKE" install -j1 "$@" || die "make.install $libs_name failed."
}

# setup cmake environments
_cmake_init() {
    test -z "$_CMAKE_READY" || return 0

    # defaults:
    : "${LIBS_BUILDDIR:=build-$PPID}"

    export LIBS_BUILDDIR

    if test -n "$_TARGET"; then
        case "$_TARGET" in
            *-linux-*)  export CMAKE_SYSTEM_NAME=Linux      ;;
            *-mingw*)   export CMAKE_SYSTEM_NAME=Windows    ;;
        esac
    fi

    # asm
    is_arm64 || {
        export CMAKE_ASM_COMPILER="$NASM"
        # these are not always working, e.g: zstd
        export CMAKE_ASM_NASM_COMPILER="$NASM"
        export CMAKE_ASM_YASM_COMPILER="$YASM"
    }
    # compatible
    if _version_ge "$("$CMAKE" --version | grep -oE "[0-9.]+" -m1)" "4.0"; then
        export CMAKE_POLICY_VERSION_MINIMUM=3.5
    fi

    # extend CC will break cmake build, set CMAKE_C_COMPILER_LAUNCHER instead
    if [ -z "$CCACHE_DISABLE" ]; then
        export CMAKE_C_COMPILER_LAUNCHER=ccache
        export CMAKE_CXX_COMPILER_LAUNCHER=ccache
    fi

    # this env depends on generator, set MAKE or others instead
    #export CMAKE_MAKE_PROGRAM="$MAKE"

    # remember envs
    {
        echo -e "\n---"
        echo -e "cmake envs:"
        env | grep -E "CMAKE"
        echo -e "---\n"
    } | _LOGGING=silent _capture

    # extend CMAKE with compile tools
    _CMAKE_STD=(
        -DCMAKE_BUILD_TYPE=RelWithDebInfo
        -DCMAKE_INSTALL_PREFIX="'$PREFIX'"
        -DCMAKE_PREFIX_PATH="'$PREFIX'"
        # rpath is meaningless for static libraries and executables
        -DCMAKE_SKIP_RPATH=TRUE
        -DCMAKE_VERBOSE_MAKEFILE=ON
    )

    # alway search -lxxx for libxxx.a
    is_mingw && _CMAKE_STD+=(
        -DCMAKE_STATIC_LIBRARY_PREFIX="lib"
        -DCMAKE_STATIC_LIBRARY_SUFFIX=".a"
    )

    # sysroot
    #local sysroot="$("$CC" -print-sysroot)"
    #test -z "$sysroot" || _CMAKE_STD+=( -DCMAKE_SYSROOT="'$sysroot'" )

    if test -n "$_TARGET"; then
        if is_darwin; then
            _CMAKE_STD+=( -DCMAKE_SYSTEM_NAME=Darwin )
        elif is_linux; then
            _CMAKE_STD+=( -DCMAKE_SYSTEM_NAME=Linux )
        elif is_mingw; then
            _CMAKE_STD+=( -DCMAKE_SYSTEM_NAME=Windows )
        fi
        # host or docker build, so `uname -m' is reliable
        _CMAKE_STD+=( -DCMAKE_SYSTEM_PROCESSOR=$(uname -m) )
    fi

    export _CMAKE_READY=1
}

_cmake_filter_out_defines() {
    local _options=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -D)     shift 2 ;;
            -D*)    shift 1 ;;
            *)      _options+=( "$1" ); shift ;;
        esac
    done
    echo "${_options[@]}"
}

cmake() {
    _cmake_init

    local cmdline=( "$CMAKE" )
    case "$(_cmake_filter_out_defines "$@")" in
        --build*)
            export CMAKE_BUILD_PARALLEL_LEVEL="$_NJOBS"
            cmdline+=( "$@" )
            ;;
        --install*)
            export CMAKE_BUILD_PARALLEL_LEVEL=1
            cmdline+=( "$@" )
            ;;
        *)
            # std
            cmdline+=( "${_CMAKE_STD[@]}" )
            # append user args
            cmdline+=( "${libs_args[@]}" "$@" )
            ;;
    esac

    slogcmd "${cmdline[@]}" || die "cmake $libs_name failed."
}

cmake.setup() {
    _cmake_init
    export CMAKE_BUILD_PARALLEL_LEVEL=1

    # std < libs_args < user args
    slogcmd "$CMAKE" -S . -B "$LIBS_BUILDDIR" "${_CMAKE_STD[@]}" "${libs_args[@]}" "$@" || die "cmake.setup $libs_name failed"

    pushd "$LIBS_BUILDDIR" || die
}

cmake.build() {
    _cmake_init
    export CMAKE_BUILD_PARALLEL_LEVEL="$_NJOBS"
    slogcmd "$CMAKE" --build . "$@" || die "cmake.build $libs_name failed."
}

cmake.install() {
    _cmake_init
    export CMAKE_BUILD_PARALLEL_LEVEL=1

    local cmdline=( "$CMAKE" )

    is_listed "--install" "$@" || cmdline+=( --install . )

    slogcmd "${cmdline[@]}" "$@" || die "cmake.install $libs_name failed."
}

_meson_init() {
    test -z "$_MESON_READY" || return 0

    : "${LIBS_BUILDDIR:=build-$PPID}"

    export LIBS_BUILDDIR

    # cross compile
    if is_mingw; then
        cat << EOF > mingw.txt
[binaries]
c = '$CC'
cpp = '$CXX'
ar = '$AR'
strip = '$STRIP'
windres = '$WINDRES'
pkgconfig = '$PKG_CONFIG'
exe_wrapper = 'wine'

[host_machine]
system = 'windows'          # Target operating system
cpu_family = '$(uname -m)'  # Target CPU family
cpu = '$(uname -m)'         # Specific CPU
endian = 'little'           # Endianness
EOF

        # gdk-pixbuf: ERROR: Program 'glib-compile-resources' not found or not executable
        #  => set find_program extensions
        export PATHEXT=".exe"
    fi

    export _MESON_READY=1
}

meson() {
    _meson_init

    local cmdline=( "$MESON" )

    # std args < meson configure
    local std=( )

    case "$1" in
        setup)
            # meson builtin options: https://mesonbuild.com/Builtin-options.html
            #  libdir: some package prefer install to lib/<machine>/
            std+=(
                -Dprefix="'$PREFIX'"
                -Dlibdir=lib
                -Dbuildtype=release
                -Ddefault_library=static    # prefer static internal project libraries
            )

            is_mingw && std+=( --cross-file=mingw.txt )

            # prefer static external dependencies
            #is_darwin || std+=( --prefer-static )

            # append user args
            cmdline+=( setup "${std[@]}" "${libs_args[@]}" "${@:2}" )
            ;;
        compile)
            cmdline+=( "$1" "${std[@]}" "${@:2}" --jobs "$_NJOBS" )
            ;;
        *)
            cmdline+=( "$1" "${std[@]}" "${@:2}" )
            ;;
    esac

    slogcmd "${cmdline[@]}" || die "meson $1 $libs_name failed."
}

meson.setup() {
    _meson_init

    local x std=()

    for x in "${libs_deps[@]}"; do
        case "$x" in
            glib)   libs.requires -DG_INTL_STATIC_COMPILATION  ;;
        esac
    done

    # meson builtin options: https://mesonbuild.com/Builtin-options.html
    #  libdir: some package prefer install to lib/<machine>/
    std+=(
        -Dprefix="'$PREFIX'"
        -Dlibdir=lib
        -Dbuildtype=release
        -Ddefault_library=static
    )

    is_mingw && std+=( --cross-file=mingw.txt )

    # prefer static external dependencies
    #is_darwin || std+=( --prefer-static )
    # prefer-static not always work for macOS, like libresolv which do not have static version.
    # prefer-static not working like expected, -static-libgcc will not working with this
    #  => use pkg-config and `-Wl,-Bstatic -latomic' instead

    # std < libs_args < user args
    slogcmd "$MESON" setup "$LIBS_BUILDDIR" "${std[@]}" "${libs_args[@]}" "$@" || die "meson.setup $libs_name failed."

    # enter builddir before return
    pushd "$LIBS_BUILDDIR" || die
}

meson.compile() {
    _meson_init

    slogcmd "$MESON" compile --verbose "-j$_NJOBS" "$@" || die "meson.compile $libs_name failed."
}

meson.install() {
    _meson_init

    slogcmd "$MESON" install "$@" || die "meson.install $libs_name failed."
}

# https://doc.rust-lang.org/cargo/reference/environment-variables.html
_cargo_init() {
    test -z "$_CARGO_READY" || return 0

    # find out rustup: $_TARGET_WORKDIR > $HOME > system
    : "${RUSTUP_HOME:=$HOME/.rustup}"   # toolchain and configurations

    test -f "$HOME/.rustup/settings.toml"     && RUSTUP_HOME="$HOME/.rustup"
    test -f "$_TARGET_WORKDIR/.rustup/settings.toml" && RUSTUP_HOME="$_TARGET_WORKDIR/.rustup"

    # set mirrors for toolchain download
    if test -n "$_MIRRORS"; then
        : "${RUSTUP_DIST_SERVER:=$_MIRRORS/rust-static}"
        : "${RUSTUP_UPDATE_ROOT:=$_MIRRORS/rust-static/rustup}"
        export RUSTUP_DIST_SERVER RUSTUP_UPDATE_ROOT
    fi

    # XXX: if rust-toolchain.toml exists, writable RUSTUP_HOME is needed
    #  choose _TARGET_WORKDIR instead of HOME for docker buildings
    if test -f rust-toolchain.toml; then
        test -w "$RUSTUP_HOME" || RUSTUP_HOME="$_TARGET_WORKDIR/.rustup"
    fi

    if ! which rustup &>/dev/null; then
        test -w "$RUSTUP_HOME" || RUSTUP_HOME="$HOME/.rustup"

        RUSTUP_INIT_OPTS=(-y --no-modify-path --profile minimal --default-toolchain stable)
        if which rustup-init &>/dev/null; then
            _LOGGING=silent echocmd rustup-init "${RUSTUP_INIT_OPTS[@]}"
        else
            _LOGGING=silent echocmd "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- ${RUSTUP_INIT_OPTS[*]}"
        fi
    fi

    # find out cargo: $_TARGET_WORKDIR > $HOME > $RUSTUP_HOME/cargo
    : "${CARGO_HOME:=$RUSTUP_HOME/cargo}"

    test -x "$HOME/.cargo/bin/cargo"     && CARGO_HOME="$HOME/.cargo"
    test -x "$_TARGET_WORKDIR/.cargo/bin/cargo" && CARGO_HOME="$_TARGET_WORKDIR/.cargo"

    # docker image RUSTUP_HOME may not be writable
    if test -w "$RUSTUP_HOME"; then
        _LOGGING=silent echocmd rustup default ||
        _LOGGING=silent echocmd rustup default stable
    fi

    export PATH="$CARGO_HOME/bin:$PATH"

    CARGO="$(rustup which cargo)" || die "missing host tool cargo"
    RUSTC="$(rustup which rustc)" || die "missing host tool rustc"

    # a writable CARGO_HOME is required, refer to cargo.requires()
    # XXX: set CARGO_HOME differ from where cargo is will cause rustup update fails
    #   => set CARGO_HOME again for local crates and cache
    test -w "$CARGO_HOME" || CARGO_HOME="$_TARGET_WORKDIR/.cargo"

    export CARGO_HOME RUSTUP_HOME CARGO RUSTC

    # refer to cargo.requires(), installed binaries must in PATH
    export PATH="$CARGO_HOME/bin:$PATH"

    # cargo logging
    #export CARGO_LOG=cargo::core::compiler::fingerprint=trace,cargo_util::paths=trace
    export CARGO_LOG=cargo::core::compiler=trace
    export CC_ENABLE_DEBUG_OUTPUT=1

    # search for libraries in PREFIX
    #  => linker=$LD fails for some crates
    CARGO_BUILD_RUSTFLAGS="--verbose -L native=$PREFIX/lib -C linker=$CC"

    if is_darwin; then
        CARGO_BUILD_TARGET="$(uname -m)-apple-darwin"

        # rustc use aarch64 instead of arm64 for macos
        CARGO_BUILD_TARGET="${CARGO_BUILD_TARGET/arm64/aarch64}"
    elif is_mingw; then
        [[ "$($CC -print-file-name=libmsvcrt.a)" =~ ^/ ]] &&
        CARGO_BUILD_RUSTFLAGS+=" -C target-feature=+crt-static"
        # win32
        #  *-windows-msvc => ucrt => vcruntime140.dll api-ms-win-crt-*.dll
        #  *-windows-gnu => msvcrt
        CARGO_BUILD_TARGET="$(uname -m)-pc-windows-gnu"
    else
        # static linked C runtime
        CARGO_BUILD_RUSTFLAGS+=" -C target-feature=+crt-static"
        # musl
        CARGO_BUILD_TARGET="$(uname -m)-unknown-linux-musl"
    fi

    # error: toolchain 'stable-xxxx-unknown-linux-musl' may not be able to run on this system
    #rustup default "stable-$CARGO_BUILD_TARGET"
    if test -n "$CARGO_BUILD_TARGET" && test -w "$RUSTUP_HOME"; then
        slogcmd rustup target add "$CARGO_BUILD_TARGET"
    fi

    export CARGO_BUILD_RUSTFLAGS CARGO_BUILD_TARGET

    mkdir -p "$CARGO_HOME"
    if ! test -e "$CARGO_HOME/config.toml"; then
        true > "$CARGO_HOME/config.toml"

        if test -n "$_CARGO_REGISTRY"; then
            local registry ver
            IFS='.' read -r ver < <("$CARGO" --version | grep -oE '[0-9\.]+')
            # cargo <= 1.68
            _version_le "$ver" 1.68 && registry="$_CARGO_REGISTRY" || registry="sparse+$_CARGO_REGISTRY"
            cat << EOF >> "$CARGO_HOME/config.toml"
[source.crates-io]
replace-with = 'crates-io-mirrors'

[source.crates-io-mirrors]
registry = "$registry"
EOF
        fi
    fi

    export _CARGO_READY=1
}

cargo() {
    _cargo_init

    local cmdline=( "$CARGO" "$1" )
    case "$1" in
        build)
            cmdline+=( "${libs_args[@]}" "${@:2}" )
            ;;
        *)
            cmdline+=( "${@:2}" )
            ;;
    esac

    slogcmd "${cmdline[@]}" || die "cargo $1 $libs_name failed."
}

# setup various rust things
cargo.setup() {
    _cargo_init

    # debug
    #export RUSTC_LOG=rustc_codegen_ssa::back::link=info

    # /usr/bin/ld: cannot find -lxcb: No such file or directory
    # XXX: -lxxx in LDFLAGS will append to rsut cc before RUSTFLAGS, and the -Lyyy will be ignored.
    #  => which cause libs.requires and LDFLAGS not working as expected.
    #   => pollute RUSTFLAGS with LDFLAGS
    set -- $LDFLAGS "$@"

    local rustflags=() x
    while [ $# -gt 0 ]; do
        case "$1" in
            -l)     rustflags+=( -l "static=$2" ); shift 1  ;;
            -l*)    rustflags+=( -l "static=${1#-l}" )      ;;
            -L)     rustflags+=( -L "$2" ); shift 1         ;;
            -L*)    rustflags+=( -L "native=${1#-L}" )      ;;
            *)      ;; # ignore other flags
        esac
        shift 1
    done

    #export RUSTFLAGS="$CARGO_BUILD_RUSTFLAGS $RUSTFLAGS ${rustflags[*]}"
    export RUSTFLAGS+="${rustflags[*]}"
    # RUSTFLAGS will append to CARGO_BUILD_RUSTFLAGS when cargo build

    # set env for static libraries
    for x in "${libs_deps[@]}"; do
        case "$x" in
            pcre2)
                export PCRE2_SYS_STATIC=1
                ;;
            libgit2)
                export LIBGIT2_NO_VENDOR=1
                ;;
            oniguruma)
                export LIBONIG_STATIC=1
                export RUSTONIG_SYSTEM_LIBONIG=1
                export RUSTONIG_STATIC_LIBONIG=1
                export RUSTONIG_DYNAMIC_LIBONIG=0
                ;;
        esac
    done
}

cargo.build() {
    _cargo_init

    # remember envs
    {
        echo -e "\n---\ncargo envs:"
        env #| grep -E "CARGO|RUST"
        echo -e "\n---\nrustc cfgs:"
        "$RUSTC" --print cfg --target "$CARGO_BUILD_TARGET"
        echo -e "---\n"
    } | _LOGGING=silent _capture

    # std < libs_args < user args
    std+=( "${libs_args[@]}" "$@" )

    # default: release
    list_has std "--release|--profile" || std+=( --release )

    list_has std "-j|--jobs" || std+=( -j "$_NJOBS" )

    # If the --target flag (or build.target) is used, then
    # the build.rustflags will only be passed to the compiler for the target.
    #test -z "$CARGO_BUILD_TARGET" || std+=( --target "$CARGO_BUILD_TARGET" )

    slogcmd "$CARGO" build --locked "${std[@]}" || die "cargo.build $libs_name failed."
}

# requires host cargo tools
cargo.requires() {
    _cargo_init

    local x
    for x in "$@"; do
        ( # always start subshell here
            # follow cargo's setting instead of ours to build host tools
            unset PREFIX CC CPP CXX CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
            unset CARGO_BUILD_RUSTFLAGS CARGO_BUILD_TARGET
            unset PKG_CONFIG PKG_CONFIG_LIBDIR PKG_CONFIG_PATH

            #export CARGO_TARGET_DIR="$CARGO_HOME/builddir" # reuse builddir

            slogcmd cargo install "$x"
        ) || die "cargo.requires $x failed."
    done
}

# requires minimal rustc version
cargo.requires.rustc() {
    _cargo_init

    _version_ge "$("$RUSTC" --version | cut -d' ' -f2)" "$1" || slogcmd rustup update
}

cargo.locate() {
    local targets=() x
    for x in "$@"; do
        targets+=( $(_locate_exe "target/$CARGO_BUILD_TARGET/release/$x") )
    done
    echo "${targets[@]}"
}

_go_init() {
    test -z "$_GO_READY" || return 0

    # defaults:
    # CGO_ENABLED=0 is necessary for build static binaries except macOS
    if is_darwin; then
        : "${CGO_ENABLED:=1}"
    else
        : "${CGO_ENABLED:=0}"
    fi

    export CGO_ENABLED

    # see _cargo_init notes

    # find go, prefer GOROOT
    test -n "$GOROOT" && GO="$GOROOT/bin/go" || GO="$(which go)"

    # install go to HOME
    if ! test -x "$GO"; then
        # there is no predefined user level GOROOT
        #  => multiple version supported
        GOROOT="$HOME/.goroot/current"

        GO="$GOROOT/bin/go"
        if ! test -x "$GO"; then
            local system arch gover

            is_darwin && system=darwin  || system=linux
            is_arm64  && arch=arm64     || arch=amd64

            gover="$(curl "https://go.dev/VERSION?m=text" | head -n1)"

            mkdir -p "${GOROOT%/*}"
            pushd "${GOROOT%/*}"

            if ! test -d "$gover"; then
                cd "${GOROOT%/*}"
                curl -fsSL "https://go.dev/dl/$gover.$system-$arch.tar.gz" | "$TAR" -xz
                mv go "$gover"
            fi

            # link as current
            rm -rf "$GOROOT"
            echocmd ln -sfv "$gover" "$GOROOT"

            popd || die
        fi
    fi

    test -x "$GO" || die "missing host tool go"

    export GO GOROOT

    # exec: "go": executable file not found in $PATH
    test -z "$GOROOT" || export PATH="$GOROOT/bin:$PATH"

    # The GOPATH directory should not be set to, or contain, the GOROOT directory.
    #  using _ROOT_/.go when build with docker =>  go cache can be reused. otherwise
    #  set GOPATH in host profile
    export GOPATH="${GOPATH:-$_ROOT_/.go}"
    #export GOCACHE="$_ROOT_/.go/go-build"
    export GOMODCACHE="$_ROOT_/.go/pkg/mod" # OR pkg installed to workdir

    export GOBIN="$PREFIX/bin"  # set install prefix
    export GO111MODULE=auto

    export CGO_CFLAGS="$CFLAGS"
    export CGO_CXXFLAGS="$CXXFLAGS"
    export CGO_CPPFLAGS="$CPPFLAGS"
    export CGO_LDFLAGS="$LDFLAGS"

    [ -z "$_GO_PROXY" ] || export GOPROXY="$_GO_PROXY"

    export _GO_READY=1
}

# go can not amend `-ldflags='
_go_filter_ldflags() {
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

_go_filter_options() {
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
    _go_init

    local cmdline=( "$GO" "$1" )
    case "$1" in
        build)
            # fix 'invalid go version'
            if [ -f go.mod ]; then
                local m n
                IFS="." read -r m n _ <<< "$("$GO" version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')"
                sed "s/^go [0-9.]\+$/go $m.$n/" -i go.mod
                # go mod edit won't work here
                #slogcmd "$GO" mod edit -go="$m.$n"
                slogcmd "$GO" mod tidy
            fi

            # verbose
            cmdline+=( -x -v )

            #1. static without dwarf and stripped
            #2. add version info
            local ldflags=( -w -s -X main.version="$libs_ver" )

            [ "$CGO_ENABLED" -ne 0 ] || ldflags+=( -extldflags=-static )

            # merge user ldflags
            ldflags+=( $(_go_filter_ldflags "${@:2}") )

            # set ldflags
            cmdline+=( -ldflags="'${ldflags[*]}'" )

            # append user options
            cmdline+=( $(_go_filter_options "${@:2}") )
            ;;
        *)
            cmdline+=( "${@:2}" )
            ;;
    esac

    slogcmd "${cmdline[@]}" || die "go $1 $libs_name failed."
}

go.setup() {
    _go_init

    # fix 'invalid go version'
    if [ -f go.mod ]; then
        local m n
        IFS="." read -r m n _ <<< "$("$GO" version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')"
        sed "s/^go [0-9.]\+$/go $m.$n/" -i go.mod
        # go mod edit won't work here
        #slogcmd "$GO" mod edit -go="$m.$n"
        slogcmd "$GO" mod tidy || true
    fi
}

go.clean() {
    _go_init

    slogcmd "$GO" clean || die "go.clean $libs_name failed."
}

go.build() {
    _go_init

    # static without dwarf and stripped
    local ldflags=( -w -s )

    # go embed version control
    if test -f main.go; then
        echo "$*" | grep -i main.version    || ldflags+=( -X main.version="$libs_ver" )
        echo "$*" | grep -i main.build      || ldflags+=( -X main.build="$((${_PKGBUILD#*=}+1))" )
    fi

    [ "$CGO_ENABLED" -ne 0 ] || ldflags+=( -extldflags=-static )

    # merge user ldflags
    ldflags+=( $(_go_filter_ldflags "$@") )

    # verbose
    local std=( -x -v -p "$_NJOBS" )

    # set ldflags
    std+=( -ldflags="'${ldflags[*]}'" )

    # append user options
    std+=( $(_go_filter_options "$@") )

    slogcmd "$GO" build "${std[@]}" || die "go.build $libs_name failed."
}

# libtool archive hardcoded PREFIX which is bad for us
_rm_libtool_archive() {
    echocmd find "${1:-$PREFIX/lib}" -name "*.la" -exec rm -f {} \; || true
}

# make install to DESTDIR to get file list
#
# Note: make install must support both DESTDIR and PREFIX
_make_install() {
    true > .pkgfile

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --) break                   ;;
            *)  echo "$1" >> .pkgfile   ;;
        esac
        shift
    done

    if [ "$1" = "--" ]; then
        shift

        # prepare DESTDIR
        rm -rf DESTDIR
        mkdir DESTDIR

        # DESTDIR must be absolute path
        local DESTDIR="$PWD/DESTDIR"
        case "$1" in
            make)   "$@" DESTDIR="$DESTDIR" ;;
            *)      DESTDIR="$DESTDIR" "$@" ;;
        esac || die "$* failed."

        _rm_libtool_archive DESTDIR || true

        # install files to PREFIX
        local file dest
        while read -r file; do
            dest="${file#DESTDIR}"      # remove leading DESTDIR
            dest="${dest#"$PREFIX"}"    # remove leading $PREFIX
            dest="${dest#/}"            # remove leading /

            mkdir -pv "$PREFIX/${dest%/*}"

            # silent logging to speed up the process in case installed huge amount of files
            cp -fv "$file" "$PREFIX/$dest" | _LOGGING=silent _capture

            echo "$dest" >> .pkgfile
        done < <(find DESTDIR ! -type d)
    fi
}

# create pkgfile
_make_pkgfile() {
    local files=()

    # preprocessing installed files
    local x
    for x in "${@:2}"; do
        # test won't work as file glob exists
        #test -e "$x" || die "$x not exists."
        case "$x" in
            # no libtool archive files
            *.la)           rm -f "$x" && continue ;;
            # no gdb files
            */gdb/*)        rm -f "$x" && continue ;;
            */valgrind/*)   rm -f "$x" && continue ;;
            # no gettext(i18n & i10n) files
            */gettext/*)    rm -f "$x" && continue ;;
            *.a)
                echocmd "$STRIP" -x "$x"
                echocmd "$RANLIB" "$x"
                ;;
            *.pc)
                # shellcheck disable=SC2016
                sed -i "$x"                                     \
                    -e 's%^prefix=.*$%prefix=\${PREFIX}%'       \
                    -e "s%$PREFIX%\${prefix}%g"                 \
                    || die "update $x failed."
                ;;
            *.cmake)
                sed -i "$x"                                     \
                    -e "s%$PREFIX%\${CMAKE_INSTALL_PREFIX}%g"   \
                    || die "update $x failed."
                ;;
            bin/*)
                test -f "$x" || x="$x$_BINEXT"  # tar will report error if not exists

                # strip binary executables
                case "$("$FILE" -b "$x")" in
                    PE32+*)             echocmd "$STRIP" --strip-all "$x"   ;;
                    ELF*)               echocmd "$STRIP" --strip-all "$x"   ;;
                    Mach-O*executable)  echocmd "$STRIP" "$x"               ;;

                    *"shell script"*)
                        case "$x" in
                            # libraries config scripts
                            *-config)
                                # replace hardcoded PREFIX with env
                                #1. prefix may be single quoted => replace prefix= first
                                #2. replace others with ${prefix}
                                sed -i "$x"                                         \
                                    -e "s%^prefix=.*%prefix=\"\${PREFIX:-/usr}\"%"  \
                                    -e "s%$PREFIX%\${prefix}%g"                     \
                                    || die "update $x failed."
                                ;;
                        esac
                    ;;
                esac
                ;;
        esac
        files+=( "$x" )
    done

    slogi "..TAR" "$1 < ${files[*]}"

    echocmd "$TAR" -czvf "$1" "${files[@]}" || die "create $1 failed."
}

# create a pkgfile with given files
cmdlet.pkgfile() {
    local name version files

    # name contains version code?
    IFS='@' read -r name version <<< "$1"

    test -z "$_BINEXT" || name="${name%$_BINEXT}"

    test -n "$version" || version="$libs_ver"

    _make_install "${@:2}"

    IFS=' ' read -r -a files < <(xargs < .pkgfile)

    test -n "${files[*]}" || die "call pkgfile() without inputs."

    pushd "$PREFIX" && mkdir -pv "$libs_name"

    # remove file prefix paths
    # shellcheck disable=SC2001
    IFS=' ' read -r -a files < <(sed -e "s%$PWD/%%g" <<< "${files[@]}")

    # pkgfile with full version and link as short version later
    local pkgfile="$libs_name/$name@$libs_ver.tar.gz"
    local pkgvern="$libs_name/$name@$libs_ver"

    # pkginfo is shared by library() and cmdlet(), full versioned
    local pkginfo="$libs_name/pkginfo@$libs_ver"; touch "$pkginfo"

    _make_pkgfile "$pkgfile" "${files[@]}"

    # there is a '*' when run sha256sum in msys
    #sha256sum "$pkgfile" >> "$pkginfo"
    IFS=' *' read -r sha _ <<< "$(sha256sum "$pkgfile")"

    sed -i "\# $pkgfile#d" "$pkginfo"
    echo "$sha $pkgfile" >> "$pkginfo"

    # create a version file
    grep -Fw "$pkgfile" "$pkginfo" > "$pkgvern"

    _pkglink() {
        echocmd ln -srf "$@"
    }

    # v2/pkginfo
    _pkglink "$pkgvern" "$libs_name/$name@latest"
    _pkglink "$pkginfo" "$libs_name/pkginfo@latest"

    if [ "$version" != "$libs_ver" ]; then
        _pkglink "$pkgvern" "$libs_name/$name@$version"
        _pkglink "$pkginfo" "$libs_name/pkginfo@$version"
    fi

    # v3/manifest is ready, keep v2/pkgfile package() only
    #  => read cmdlete.sh:package() for more details
    #if [ "$version" != "$libs_ver" ]; then
    #    _make_link "$libs_name/$name@$version" "$name@$version"
    #else
    #    _make_link "$libs_name/$name@latest"   "$name@latest"
    #fi

    # v3/manifest: name pkgfile sha build
    # clear versioned records
    sed -i "\#^$1 $pkgfile #d" "$_TARGET_MANIFEST"
    # new records
    echo "$1 $pkgfile $sha build=$((${_PKGBUILD#*=}+1))" >> "$_TARGET_MANIFEST"

    popd || die "popd failed."
}

# disclam specific version of cmdlet from manifest
#  input: version ...
cmdlet.disclaim() {
    local x
    for x in "$@"; do
        sed -i "\#\ $libs_name/.*@$x#d" "$_TARGET_MANIFEST" || true
    done
}

# install files and create a pkgfile
#  input: name                          \
#         [include]         header.h    \
#         include/xxx       xxx.h       \
#         [lib]             libxxx.a    \
#         [lib/pkgconfig]   xxx.pc      \
#         bin               xxx         \
#         share             yyy         \
#         share/man         zzz
cmdlet.pkginst() {
    local name="$1"; shift

    slogi ".Inst" "$name < $*"

    local sub installed
    while [ $# -ne 0 ]; do
        local file="$1"; shift
        case "$file" in
            # no libtool archive files
            *.la) continue ;;

            # set default path for specified files
            *.h|*.hxx|*.hpp)    [[ "$sub" =~ ^include        ]] || sub="include"        ;;
            *.cmake)            [[ "$sub" =~ ^lib/cmake      ]] || sub="lib/cmake"      ;;
            *.a|*.so|*.so.*)    [[ "$sub" =~ ^lib            ]] || sub="lib"            ;;
            *.pc)               [[ "$sub" =~ ^lib/pkgconfig  ]] || sub="lib/pkgconfig"  ;;

            # set sub dir for known directories
            include|include/*|lib|lib/*|share|share/*|bin)
                sub="$file"
                mkdir -pv "$PREFIX/$sub"
                continue
                ;;
            *)
                # treat as normal files and install to sub
                test -n "$sub" || die "pkginst without subdir"
                ;;
        esac

        [[ "$sub" =~ ^bin ]] && file="$(_locate_exe "$file")"

        echocmd cp -rfv "$file" "$PREFIX/$sub" || die "install $file failed."
        installed+=( "$sub/${file##*/}" )
    done

    cmdlet.pkgfile "$name" "${installed[@]}"
}

# cmdlet executable [name] [alias ...]
cmdlet.install() {
    slogi ".Inst" "install cmdlet $1 => ${2:-"${1##*/}"} (alias ${*:3})"

    # executable
    local bin="$(_locate_exe "$1")" ext
    test -f "$bin" || die "$bin not found."
    test -n "$_BINEXT" && [[ "$bin" =~ $_BINEXT$ ]] && ext="$_BINEXT"

    # target
    local target="$PREFIX/bin/${2:-"${bin##*/}"}"
    [[ "$target" =~ $ext$ ]] || target="$target$ext"
    echocmd "$INSTALL" -m755 "$bin" "$target" || die "install $libs_name failed"

    if is_mingw; then
        # no symbolic links for win32
        _install_alias() {
            echocmd cp -f "$1" "$2"
        }
    else
        _install_alias() {
            echocmd ln -srf "$1" "$2"
        }
    fi

    # alias
    local alias=( "${@:3}" ) lnk
    test -z "$ext" || alias=( "${alias[@]/%/$ext}" )
    for lnk in "${alias[@]}"; do
        rm -f "$PREFIX/bin/$lnk" || true
        _install_alias "$target" "$PREFIX/bin/$lnk"
    done

    # pack
    cmdlet.pkgfile "${target##*/}" "$target" "${alias[@]/#/$PREFIX\/bin\/}"
}

# perform visual check on cmdlet
cmdlet.check() {
    slogi "..Run" "check $*"

    local bin="$(_locate_bin "$1")"

    test -f "$bin" || die "check failed, $1 not found."

    # check file type
    echocmd "$FILE" -b "$bin"

    # check linked libraries
    if is_linux; then
        "$FILE" -b "$bin" | grep -Fw "dynamically linked" && {
            echocmd ldd "$bin"
            die "$bin is dynamically linked."
        } || true
    elif is_darwin; then
        _LOGGING=plain echocmd otool -L "$bin" | grep -qE "/usr/local/|/opt/homebrew/|$PREFIX/lib|@rpath/.*\.dylib" && die "unexpected linked libraries" || true
    elif is_mingw; then
        local dll system32="system32"
        while read -r dll; do
            [[ "$dll" =~ KERNEL32.dll|msvcrt.dll ]] && continue

            if test -n "$WINEPREFIX"; then
                is_win64 || system32="syswow64"
                find "$WINEPREFIX/drive_c/windows/$system32" -iname "$dll" || die "unexpected dll $dll"
            else
                [[ "$($CC -print-file-name="$dll")" =~ ^/ ]] || die "unexpected dll $dll"
            fi

        done < <( objdump -p "$bin" | grep -Fw "DLL Name:" | cut -d':' -f2 )
    else
        slogw "FIXME: $OSTYPE"
    fi

    # check version if options/arguments provide
    if [ $# -gt 1 ]; then
        run "$bin" "${@:2}" 2>&1 | grep -F "$libs_ver" || die "no version found"
    fi
}

cmdlet.caveats() {
    # no version for caveats file
    caveats="$PREFIX/$libs_name/$libs_name.caveats"

    slogi "Caveats:"
    if test -n "$*"; then
        echo "$*" | tee -a "$caveats" || die "write caveats failed."
    else
        tee -a "$caveats" || die "write caveats failed."
    fi
}

# run command or die
run() {
    local bin="$(_locate_bin "$1")"

    test -f "$bin" || die "$1 not found."

    _run() {
        # > stderr, avoid grep by pipe commands
        echo "$@" | _LOGGING=silent _capture_stderr

        # do not redirect stderr to stdout, vice versa
        #  always logging as plain for piping
        "$@" 2> >(_LOGGING=plain _capture_stderr) | _LOGGING=plain _capture
    }

    # capture only stderr to keep stdout as it is
    if test -n "$WINEPREFIX"; then
        case "$("$FILE" -b "$bin")" in
            PE32+*)
                # escape won't work for wine/cmd, which do not treat ' as quotation marks
                #_run "$WINE" "$bin" $(escape.args "${@:2}") | escape.crlf
                _run "$WINE" "$bin" "${@:2}" | escape.crlf
                ;;
            *)
                _run "$SHELL" -c "$bin $(escape.args "${@:2}")"
                ;;
        esac
    else
        # use shell to catch "Killed" or "Abort trap" messages
        _run "$SHELL" -c "$bin $(escape.args "${@:2}")"
    fi
}

# deprecated
pkginst()   { cmdlet.pkginst "$@";  }
pkgfile()   { cmdlet.pkgfile "$@";  }
cmdlet()    { cmdlet.install "$@";  }
check()     { cmdlet.check "$@";    }
caveats()   { cmdlet.caveats "$@" ; }

# find out which files are installed by `make install'
inspect() {
    find "$PREFIX" > "$libs_name.pack.pre"

    slogcmd "$@" || die "${*:2} failed."

    _rm_libtool_archive

    find "$PREFIX" > "$libs_name.pack.post"

    # diff returns 1 if differences found
    diff "$libs_name.pack.post" "$libs_name.pack.pre" || true
}

# create pkg config file
#  input: name -l.. -L.. -I.. -D..
cmdlet.pkgconf() {
    local name="${1%.pc}"; shift

    local cflags=()
    local ldflags=()
    local requires=()

    while [ $# -gt 0 ]; do
        local arg="$1"; shift 1
        case "$arg" in
            -I*|-D*)    cflags+=( "$arg" )              ;;
            -l*|-L*)    ldflags+=( "$arg" )             ;;
            -framework) ldflags+=( "$arg" "$1" ); shift ;; # -framework AppKit
            -pthread)   ldflags+=( "$arg" )             ;; # -pthread
            -*)         cflags+=( "$arg" )              ;; # -DXXX -std=xxx
            *)          requires+=( "$arg" )            ;;
        esac
    done

    slogi "..Fix" "$name.pc < ${cflags[*]} ${ldflags[*]} ${requires[*]}"

    if test -f "$name.pc"; then
        # append missing fields
        local x
        for x in Cflags Libs Requires; do
            grep -Eq "^$x:" "$name.pc" || echo "$x:" >> "$name.pc"
        done

        # amend arguments to pc file
        sed -i "$name.pc"                           \
            -e "/Requires:/s%$% ${requires[*]}%"    \
            -e "/Cflags:/s%$% ${cflags[*]}%"        \
            -e "/Libs:/s%$% ${ldflags[*]}%"         \
            || die "fix $name.pc failed"
    else
        cat <<EOF > "$name.pc"
prefix=\${PREFIX}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: ${name##*/}
Description: ${name##*/} static library
Version: $libs_ver

Requires: ${requires[@]}
Cflags: -I\${includedir} ${cflags[@]}
Libs: -L\${libdir} ${ldflags[@]}
EOF
    fi

}
pkgconf() { cmdlet.pkgconf "$@";  }

# create static library archive
cmdlet.archive() {
    local name="${1%.a}"; shift

    slogi "...AR" "$name < $@"

    if is_darwin; then
        echocmd libtool -static -o "$name.a" "$@"
    else
        echocmd "$AR" rcs "$name.a" "$@"
    fi
}

# hack local symbols: append function with a random(pid) suffix
#   input: filename function
hack.c.symbols() {
    # void cache_init(struct cache *cache);
    #
    # =>
    #
    # void cache_init_xxxx(struct cache *cache);
    # #define cache_init cache_init_xxxx

    # use suffix instead of prefix to keep func syntax
    local suffix="$$"

    # append random for multiple hacks
    suffix+="_$(openssl rand -hex 4)"

    # insert or append macro
    if grep -wq "$2\s*(.*);" "$1"; then
        sed -i "$1" \
            -e "/\<$2\>\s*(/a #define $2 $2_$suffix" \
            -e "/\<$2\>\s*(/s/\<$2\>/$2_$suffix/"
    else
        sed -i "$1" \
            -e "/\<$2\>\s*(/i #define $2 $2_$suffix" \
            -e "/\<$2\>\s*(/s/\<$2\>/$2_$suffix/"
    fi
}

# set symbols as static
hack.c.static() {
    # void __noreturn __abi_breakage(const char *file, int line, const char *reason)
    sed -i "$1" -e "/\<$2\>\s*(/s/^/static /"
}

# remove predefined variables in Makefile and use env instead
#  input: Makefile variables...
hack.makefile() {
    local x
    for x in "${@:2}"; do
        case "$x" in
            *FLAGS) # append flags (only the first match)
                sed -i "0,/^$x[[:blank:]]*:\?=/{ s/^$x[[:blank:]]*:\?=/$x += /; }" "$1"
                ;;
            *)      # delete others (only the first match)
                sed -i "0,/^$x[[:blank:]]*:\?=/{ /^$x[[:blank:]]*:\?=/d; }" "$1"
                ;;
        esac
    done
}

# no pcre2-config, use a hack function instead
#  input: <path to configure or Makefile>
hack.pcre2() {
    # no shared pcre2, refer to src/config.h
    unset PCRE2POSIX_SHARED

    sed -i "$1" -r \
        -e '/pcre2-config/ {
                s/pcre2-config/$PKG_CONFIG/g;
                s/--cflags(.*)/--cflags libpcre2\1/g;
                s/--libs(.*)/--libs libpcre2\1/g;
            }' \
        -e '/\$PCRE_CONFIG/ {
                s/PCRE_CONFIG/PKG_CONFIG/g;
                s/--cflags(.*)/--cflags libpcre2\1/g;
                s/--libs(.*)/--libs libpcre2\1/g;
            }'
}

visibility.hidden() {
    CFLAGS+=" -fvisibility=hidden -fvisibility-inlines-hidden"
    CXXFLAGS+=" -fvisibility=hidden -fvisibility-inlines-hidden"

    export CFLAGS CXXFLAGS
}

if [[ "$0" =~ helpers.sh$ ]]; then
    cd "$(dirname "$0")"
    . libs.sh
    "$@" || exit $?
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
