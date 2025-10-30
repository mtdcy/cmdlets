#!/bin/bash
#
# helpers for build static libraries
#
# this file be loaded when compile targets
#
# warning: variable not assigned
# shellcheck disable=SC2154

# show git tag > branch > commit
git_version() {
    git describe --tags --exact-match 2> /dev/null ||
    git symbolic-ref -q --short HEAD ||
    git rev-parse --short HEAD
}

apply_c89_flags() {
    local flags=()

    if is_clang; then
        flags+=(
            -Wno-implicit-int
            -Wno-incompatible-pointer-types
            -Wno-implicit-function-declaration
        )
    else
        flags+=(
            -Wno-error=implicit-int
            -Wno-error=incompatible-pointer-types
            -Wno-error=implicit-function-declaration
        )
    fi

    export CFLAGS+=" ${flags[*]}"
}

deparallelize() {
    export CL_NJOBS=1
}

depends_on() {
    "$@" || {
        slogw "*****" "**** Not supported on $OSTYPE! ****"
        exit 0 # exit shell
    }
}

configure() {
    if ! test -f configure; then
        if test -f autogen.sh; then
            slogcmd ./autogen.sh
        elif test -f bootstrap; then
            slogcmd ./bootstrap
        elif test -f configure.ac; then
            slogcmd autoreconf -fis
        fi
    fi

    local cmdline

    cmdline=( ./configure --prefix="$PREFIX" )

    # append user args
    cmdline+=( "${libs_args[@]}" "$@" )

    slogcmd "${cmdline[@]}" || die "configure $* failed."
}

make() {
    local cmdline=( "$MAKE" "$@" )

    # set default njobs
    [[ "${cmdline[*]}" =~ -j[0-9\ ]* ]] || cmdline+=( -j"$CL_NJOBS" )

    [[ "${cmdline[*]}" =~ \ V=[0-9]+ ]] || cmdline+=( V=1 )

    slogcmd "${cmdline[@]}" || die "make $* failed."
}

# setup cmake environments
_cmake_init() {
    test -z "$CMAKE_READY" || return 0

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

    # this env depends on generator, set MAKE or others instead
    #export CMAKE_MAKE_PROGRAM="$MAKE"

    export CMAKE_READY=1
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
            export CMAKE_BUILD_PARALLEL_LEVEL="$CL_NJOBS"
            cmdline+=( "$@" )
            ;;
        --install*)
            export CMAKE_BUILD_PARALLEL_LEVEL=1
            cmdline+=( "$@" )
            ;;
        *)
            # extend CMAKE with compile tools
            cmdline+=(
                -DCMAKE_BUILD_TYPE=RelWithDebInfo
                -DCMAKE_INSTALL_PREFIX="'$PREFIX'"
                -DCMAKE_PREFIX_PATH="'$PREFIX'"
                # rpath is meaningless for static libraries and executables
                -DCMAKE_SKIP_RPATH=TRUE
                -DCMAKE_VERBOSE_MAKEFILE=ON
            )
            # sysroot
            is_darwin || cmdline+=(
                -DCMAKE_SYSROOT="'$($CC -print-sysroot)'"
            )
            # cmake using a mixed path style with MSYS Makefiles, why???
            is_msys && cmdline+=( -G"'MSYS Makefiles'" )
            # append user args
            cmdline+=( "${libs_args[@]}" "$@" )
            ;;
    esac

    slogcmd "${cmdline[@]}" || die "cmake $* failed."
}

meson() {
    local cmdline=( "$MESON" )

    # global args < meson configure
    args=(
    )

    case "$1" in
        setup)
            # meson builtin options: https://mesonbuild.com/Builtin-options.html
            #  libdir: some package prefer install to lib/<machine>/
            args+=(
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
            cmdline+=( setup "${args[@]}" "${libs_args[@]}" "${@:2}" )
            ;;
        *)
            cmdline+=( "$1" "${args[@]}" "${@:2}" )
            ;;
    esac

    slogcmd "${cmdline[@]}" || die "meson $* failed."
}

ninja() {
    local cmdline

    # append user args
    cmdline=( "$NINJA" -j "$CL_NJOBS" -v "$@" )

    slogcmd "${cmdline[@]}" || die "ninja $* failed."
}

# https://doc.rust-lang.org/cargo/reference/environment-variables.html
_cargo_init() {
    test -z "$CARGO_READY" || return 0

    # always use default value $HOME/.cargo, as
    # host act runner won't inherit envs from host and
    # $ROOT will be deleted when jobs finished.

    # rustup and cargo
    export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"

    # always prepend cargo bin to PATH
    export PATH="$CARGO_HOME/bin:$PATH"

    # we need rustup to add target
    if ! which rustup; then
        # RUSTUP_HOME: toolchain and configurations
        export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"

        mkdir -p "$RUSTUP_HOME" "$CARGO_HOME"

        if test -n "$CL_MIRRORS"; then
            export RUSTUP_DIST_SERVER=$CL_MIRRORS/rust-static
            export RUSTUP_UPDATE_ROOT=$CL_MIRRORS/rust-static/rustup
        fi

        RUSTUP_INIT_OPTS=(-y --no-modify-path --profile minimal --default-toolchain stable)
        if which rustup-init; then
            rustup-init "${RUSTUP_INIT_OPTS[@]}"
        else
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- "${RUSTUP_INIT_OPTS[@]}"
        fi
    else
        rustup default || rustup default stable
    fi

    CARGO="$(rustup which cargo)" || die "missing host tool cargo"
    RUSTC="$(rustup which rustc)" || die "missing host tool rustc"

    export CARGO RUSTC

    # set CARGO_HOME again for local crates and cache
    export CARGO_HOME="$ROOT/.cargo"
    export CARGO_BUILD_JOBS="$CL_NJOBS"

    mkdir -p "$CARGO_HOME"

    # search for libraries in PREFIX
    CARGO_BUILD_RUSTFLAGS="-L$PREFIX/lib"

    if is_linux; then
        # static linked C runtime
        CARGO_BUILD_RUSTFLAGS+=" -C target-feature=+crt-static"

        CARGO_BUILD_TARGET="$(uname -m)-unknown-linux-musl"
        rustup target add "$CARGO_BUILD_TARGET"
    fi

    export CARGO_BUILD_RUSTFLAGS CARGO_BUILD_TARGET

    # https://docs.rs/pkg-config/latest/pkg_config/
    #export PKG_CONFIG="$(which pkg-config)" # rust pkg-config do not support parameters
    export PKG_CONFIG_ALL_STATIC=true   # pass --static for all libraries
    # FOO_STATIC - pass --static for the library foo

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
    fi

    export CARGO_READY=1
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

    slogcmd "${cmdline[@]}" || die "cargo $* failed."
}

_go_init() {
    test -z "$GO_READY" || return 0

    # see _cargo_init notes

    # there is no predefined user level GOROOT
    if ! which go; then
        export GOROOT="${GOROOT:-$HOME/.goroot/current}"
        export PATH="$GOROOT/bin:$PATH"
    fi

    if ! which go; then
        local system arch version
        is_darwin && system=darwin  || system=linux
        is_arm64  && arch=arm64     || arch=amd64
        version="$(curl https://go.dev/VERSION?m=text | head -n1)"

        mkdir -pv "${GOROOT%/*}" && pushd "${GOROOT%/*}" || die

        test -d "$version" || {
            curl -fsSL "https://go.dev/dl/$version.$system-$arch.tar.gz" | "$TAR" -xz
            mv go "$version"
        }

        ln -sfv "$version" "$GOROOT"
        popd || die
    fi

    GO="$(which go)" || die "missing host tool go."

    export GO

    # The GOPATH directory should not be set to, or contain, the GOROOT directory.
    #  using ROOT/.go when build with docker =>  go cache can be reused. otherwise
    #  set GOPATH in host profile
    export GOPATH="${GOPATH:-$ROOT/.go}"
    #export GOCACHE="$ROOT/.go/go-build"
    #export GOMODCACHE="$ROOT/.go/pkg/mod"

    export GOBIN="$PREFIX/bin"  # set install prefix
    export GO111MODULE=auto

    export CGO_CFLAGS="$CFLAGS"
    export CGO_CXXFLAGS="$CXXFLAGS"
    export CGO_CPPFLAGS="$CPPFLAGS"
    export CGO_LDFLAGS="$LDFLAGS"

    [ -z "$CL_MIRRORS" ] || export GOPROXY="$CL_MIRRORS/gomods"

    export GO_READY=1
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

    # CGO_ENABLED=0 is necessary for build static binaries except macOS
    export CGO_ENABLED="${CGO_ENABLED:-0}"

    local cmdline=("$GO" "$1" )
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

    slogcmd "${cmdline[@]}" || die "go $* failed."
}

# easy command for go project
go_build() {
    go clean || true
    go build "$@"
}

# libtool archive hardcoded PREFIX which is bad for us
_rm_libtool_archive() {
    CL_LOGGING=silent \
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

        _rm_libtool_archive DESTDIR

        # copy files to PREFIX
        local dest
        while read -r file; do
            dest="${file#DESTDIR}"      # remove leading DESTDIR
            dest="${dest#"$PREFIX"}"    # remove leading $PREFIX
            dest="${dest#/}"            # remove leading /

            mkdir -pv "$PREFIX/$(dirname "$dest")"

            echocmd cp -fv "$file" "$PREFIX/$dest"

            echo "$dest" >> .pkgfile
        done < <(find DESTDIR ! -type d)
    fi
}

# create pkgfile
_pack() {
    local files=()

    # preprocessing installed files
    for x in "${@:2}"; do
        # test won't work as file glob exists
        #test -e "$x" || die "$x not exists."
        case "$x" in
            # no libtool archive files
            *.la) continue ;;
            *.a)
                echocmd "$STRIP" -x "$x"
                echocmd "$RANLIB" "$x"
                ;;
            *.pc)
                # shellcheck disable=SC2016
                sed -e 's%^prefix=.*$%prefix=\${PREFIX}%' \
                    -e "s%$PREFIX%\${prefix}%g" \
                    -i "$x"
                ;;
            bin/*)
                if test -f "$x"; then
                    test -n "$BIN_STRIP" && echocmd "$BIN_STRIP" "$x" || echocmd "$STRIP" "$x"
                fi
                ;;
        esac
        files+=( "$x" )
    done

    slogi ".Pack" "$1 < ${files[*]}"

    echocmd "$TAR" -czvf "$1" "${files[@]}" || die "create $1 failed."
}

# link source target
_ln() {
    #echo "link: $1 => $2" >&2
    if is_msys; then
        echocmd cp -vf "$1" "$2"
    else
        echocmd ln -srvf "$1" "$2"
    fi
}

# create a pkgfile with given files
pkgfile() {
    local name version files

    # name contains version code?
    IFS='@' read -r name version <<< "$1"

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

    _pack "$pkgfile" "${files[@]}"

    # there is a '*' when run sha256sum in msys
    #sha256sum "$pkgfile" >> "$pkginfo"
    IFS=' *' read -r sha _ <<< "$(sha256sum "$pkgfile")"

    sed -i "\# $pkgfile#d" "$pkginfo"
    echo "$sha $pkgfile" >> "$pkginfo"

    # create a version file
    grep -Fw "$pkgfile" "$pkginfo" > "$pkgvern"

    # v2/pkginfo
    _ln "$pkgvern" "$libs_name/$name@latest"
    _ln "$pkginfo" "$libs_name/pkginfo@latest"

    if [ "$version" != "$libs_ver" ]; then
        _ln "$pkgvern" "$libs_name/$name@$version"
        _ln "$pkginfo" "$libs_name/pkginfo@$version"
    fi

    # v3/manifest is ready, keep v2/pkgfile package() only
    #  => read cmdlete.sh:package() for more details
    #if [ "$version" != "$libs_ver" ]; then
    #    _ln "$libs_name/$name@$version" "$name@$version"
    #else
    #    _ln "$libs_name/$name@latest"   "$name@latest"
    #fi

    test -n "$PKGBUILD" || PKGBUILD="build=0"

    # v3/manifest: name pkgfile sha build
    # clear versioned records
    sed -i "\#^$1 $pkgfile #d" cmdlets.manifest
    # new records
    echo "$1 $pkgfile $sha build=$((${PKGBUILD#*=}+1))" >> cmdlets.manifest

    popd || die "popd failed."
}

# install files and create a pkgfile
#  input: name                     \
#         [include]       header.h \
#         include/xxx     xxx.h    \
#         [lib]           libxxx.a \
#         [lib/pkgconfig] xxx.pc   \
#         share           yyy      \
#         share/man       zzz
pkginst() {
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
            include|include/*|lib|lib/*|share|share/*|bin|bin/*)
                sub="$file"
                mkdir -pv "$PREFIX/$sub"
                continue
                ;;

            # reuse previous sub dir for other files
        esac

        echocmd cp -fv "$file" "$PREFIX/$sub" || die "install $file failed."
        installed+=( "$sub/${file##*/}" )
    done

    pkgfile "$name" "${installed[@]}"
}

# find out which files are installed by `make install'
inspect() {
    find "$PREFIX" > "$libs_name.pack.pre"

    slogcmd "$@" || die "${*:2} failed."

    _rm_libtool_archive

    find "$PREFIX" > "$libs_name.pack.post"

    # diff returns 1 if differences found
    diff "$libs_name.pack.post" "$libs_name.pack.pre" || true
}

# cmdlet executable [name] [alias ...]
cmdlet() {
    slogi ".Inst" "install cmdlet $1 => ${2:-"${1##*/}"} (alias ${*:3})"

    local target="$PREFIX/bin/${2:-"${1##*/}"}"

    echocmd "$INSTALL" -v -m755 "$1" "$target" || die "install $1 failed"

    local alias=()
    for x in "${@:3}"; do
        _ln "$target" "$PREFIX/bin/$x"
        alias+=( "$PREFIX/bin/$x" )
    done

    pkgfile "${target##*/}" "$target" "${alias[@]}"
}

# perform visual check on cmdlet
check() {
    slogi "..Run" "check $*"

    # try prebuilts first
    local bin="$PREFIX/bin/$1"

    # try local file again
    test -f "$bin" || bin="$1"

    test -f "$bin" || die "check $* failed, $bin not found."

    # print to tty instead of capture it
    file "$bin"

    # check version if options/arguments provide
    if [ $# -gt 1 ]; then
        echocmd "$bin" "${@:2}" 2>&1 | grep -Fw "$libs_ver"
    fi

    # check linked libraries
    if is_linux; then
        file "$bin" | grep -Fw "dynamically linked" && {
            echocmd ldd "$bin"
            die "$bin is dynamically linked."
        } || true
    elif is_darwin; then
        echocmd otool -L "$bin" # | grep -v "libSystem.*"
    elif is_msys; then
        echocmd ntldd "$bin"
    else
        slogw "FIXME: $OSTYPE"
    fi
}

caveats() {
    # no version for caveats file
    pkgfile="$PREFIX/$libs_name/$libs_name.caveats"

    slogi "Caveats:"
    if test -n "$*"; then
        echo "$*" | tee -a "$pkgfile"
    else
        while IFS= read -r line; do
            echo "$line" | tee -a "$pkgfile"
        done
    fi
}

# create pkg config file
#  input: name -l.. -L.. -I.. -D..
pkgconf() {
    local name="${1%.pc}"; shift

    local cflags=()
    local ldflags=()
    local requires=()
    for arg in "$@"; do
        case "$arg" in
            -I*|-D*)    cflags+=( "$arg" )      ;;
            -l*|-L*)    ldflags+=( "$arg" )     ;;
            *)          requires+=( "-l$arg" )   ;;
        esac
    done

    slogi "...pc" "$name.pc < ${cflags[*]} ${ldflags[*]}"

    cat <<EOF > "$PKG_CONFIG_PATH/$name.pc"
prefix=\${PREFIX}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: $name
Description: $name static library
Version: $libs_ver

Requires: ${requires[*]}
Libs: -L\${libdir} ${ldflags[*]}
Cflags: -I\${includedir} ${cflags[*]}
EOF
}

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
