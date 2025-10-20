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

_filter_out_cmake_defines() {
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

    local cmdline=( "$CMAKE" )

    case "$(_filter_out_cmake_defines "$@")" in
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
_init_rust() {
    test -z "$RUST_READY" || return 0

    if which rustup &>/dev/null; then
        CARGO="$(rustup which cargo)"
        RUSTC="$(rustup which rustc)"
    else
        CARGO="$(which cargo)"
        RUSTC="$(which rustc)"
    fi

    test -n "$CARGO" || die "missing host tool rustup/cargo."

    export CARGO RUSTC

    # cargo/rust
    CARGO_HOME="$ROOT/.cargo"
    CARGO_BUILD_JOBS="$CL_NJOBS"

    mkdir -p "$CARGO_HOME"

    export CARGO_HOME CARGO_BUILD_JOBS

    # static linked target
    if is_linux; then
        export CARGO_BUILD_TARGET="$(uname -m)-unknown-linux-musl"
        export CARGO_BUILD_RUSTFLAGS="-C target-feature=+crt-static"

        # https://docs.rs/pkg-config/latest/pkg_config/
        export PKG_CONFIG_ALL_STATIC=true   # pass --static for all libraries
    fi

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

    export RUST_READY=1
}

cargo() {
    _init_rust

    local cmdline=( "$CARGO" "$@" "${libs_args[@]}" )

    slogcmd "${cmdline[@]}" || die "cargo $* failed."
}

_init_go() {
    test -z "$GO_READY" || return 0

    GO="$(which go)"

    test -n "$GO" || die "missing host tool go."

    # no GOROOT or GOPATH here
    export GOMODCACHE="$ROOT/.go/pkg/mod"
    export GOBIN="$PREFIX/bin"  # set install prefix
    export GO111MODULE=auto

    # CGO_ENABLED=0 is necessary for build static binaries
    export CGO_ENABLED=0
    export CGO_CFLAGS="$CFLAGS"
    export CGO_CXXFLAGS="$CXXFLAGS"
    export CGO_CPPFLAGS="$CPPFLAGS"
    export CGO_LDFLAGS="$LDFLAGS"

    [ -z "$CL_MIRRORS" ] || export GOPROXY="$CL_MIRRORS/gomods"

    export GO_READY=1
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
    _init_go

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

    slogcmd CGO_ENABLED="$CGO_ENABLED" "${cmdline[@]}" || die "go $* failed."
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
    shift

    test -n "$version" || version="$libs_ver"

    _make_install "$@"

    IFS=' ' read -r -a files < <(xargs < .pkgfile)

    test -n "${files[*]}" || die "call pkgfile() without inputs."

    pushd "$PREFIX" && mkdir -pv "$libs_name"

    # remove file prefix paths
    # shellcheck disable=SC2001
    IFS=' ' read -r -a files < <(sed -e "s%$PWD/%%g" <<< "${files[@]}")

    # pkgfile with full version
    local pkgfile="$libs_name/$name@$libs_ver.tar.gz"
    local pkgvern="$libs_name/$name@$libs_ver"

    # pkginfo is shared by library() and cmdlet(), full versioned
    local pkginfo="$libs_name/pkginfo@$libs_ver"; touch "$pkginfo"

    _pack "$pkgfile" "${files[@]}"

    # there is a '*' when run sha256sum in msys
    #sha256sum "$pkgfile" >> "$pkginfo"
    IFS=' *' read -r sha _ <<< "$(sha256sum "$pkgfile")"
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

    if [ "$version" != "$libs_ver" ]; then
        _ln "$libs_name/$name@$version" "$name@$version"
    else
        _ln "$libs_name/$name@latest"   "$name@latest"
    fi

    # v3/manifest: name pkgfile sha
    # clear versioned records
    sed -i "\#^$1 $pkgfile #d" cmdlets.manifest
    # new records
    echo "$1 $pkgfile $sha" >> cmdlets.manifest

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

_rm_libtool_archive 2>&1

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
