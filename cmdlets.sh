#!/bin/bash -e
#
# shellcheck disable=SC2155

set -eo pipefail
export LANG="${LANG:-en_US.UTF-8}"

VERSION=0.3

WORKDIR="$(dirname "$0")"
ARCH="${CMDLETS_ARCH:-}" # auto resolve arch later
PREBUILTS="${CMDLETS_PREBUILTS:-$WORKDIR/prebuilts}"

REPO=(
    "${CMDLETS_MAIN_REPO:-https://pub.mtdcy.top:8443/cmdlets/latest}"
)

BASE=(
    "https://git.mtdcy.top/mtdcy/cmdlets/raw/branch/main/cmdlets.sh"
    "https://raw.githubusercontent.com/mtdcy/cmdlets/main/cmdlets.sh"
)

CURL_OPTS=( -L --fail --connect-timeout 3 --progress-bar --no-progress-meter )

# never resolve symbolic of "$0"
_name="$(basename "$0")"

usage() {
    cat << EOF
$_name $VERSION
Copyright (c) 2025, mtdcy.chen@gmail.com

$_name options [args ...]

Options:
    update                  - update $_name
    fetch   <cmdlet>        - fetch cmdlet(s) from server
    install <cmdlet>        - fetch and install cmdlet(s)
    library <libname>       - fetch a library from server
    package <pkgname>       - fetch a package(cmdlets & libraries) from server
    help                    - show this help message

Examples:
    $_name install minigzip                 # install the latest version
    $_name install zlib/minigzip@1.3.1-2    # install the specific version

    $_name package zlib                     # install the latest package
    $_name package zlib@1.3.1-2             # install the specific version
EOF
}

error() { echo -ne "\\033[31m$*\\033[39m"; }
info()  { echo -ne "\\033[32m$*\\033[39m"; }
warn()  { echo -ne "\\033[33m$*\\033[39m"; }

# is file existing in repo
_exists() (
    local source
    for repo in "${REPO[@]}"; do
        [[ "$1" =~ ^https?:// ]] && source="$1" || source="$repo/$ARCH/$1"
        curl -sI "${CURL_OPTS[@]}" "$source" -o /dev/null && return 0 || true
    done
    return 1
)

# curl file to destination
_curl() (
    local source
    mkdir -p "$(dirname "$2")"
    for repo in "${REPO[@]}"; do
        [[ "$1" =~ ^https?:// ]] && source="$1" || source="$repo/$ARCH/$1"
        curl -S "${CURL_OPTS[@]}" "$source" -o "$2" && return 0 || true
    done
    return 1
)

# save package to PREBUILTS
_save() (
    local source
    mkdir -p "$PREBUILTS"
    for repo in "${REPO[@]}"; do
        [[ "$1" =~ ^https?:// ]] && source="$1" || source="$repo/$ARCH/$1"
        curl -S "${CURL_OPTS[@]}" "$source" | tar -C "$PREBUILTS" -xz && return 0 || true
    done
    return 1
)

# get remote revision url
_revision() {
    # zlib
    # zlib@1.3.1
    # zlib/minigzip@1.3.1
    IFS='@' read -r pkg ver <<< "$1"
    if [ -n "$ver" ]; then
        IFS='/' read -r a b <<< "$pkg"
        [ -n "$b" ] && echo "$1" || echo "$a/$a@$ver"
    else
        echo "$pkg@latest"
    fi
}

# get remote pkginfo url
_pkginfo() {
    # zlib@1.3.1-2
    IFS='@' read -r pkg ver <<< "$1"
    IFS='-' read -r ver fix <<< "$ver"
    if [ -n "$ver" ] && [ "$ver" != "latest" ]; then
        echo "$pkg/pkginfo@$ver-${fix:-0}"
    else
        echo "$pkg/pkginfo@latest"
    fi
}

# fetch cmdlet from server
cmdlet() {
    local pkgname revision
    
    # shellcheck disable=SC2064
    revision="$(mktemp)" && trap "rm -f $revision" EXIT

    # cmdlet v2
    if _curl "$(_revision "$1")" "$revision"; then
        IFS=' ' read -r _ pkgname _ <<< "$(tail -n1 "$revision")"
        info "Fetch $pkgname => $PREBUILTS "
        _save "$pkgname" || return 1
        echo -ne "\n"
    # cmdlet v1/raw mode
    elif _exists "bin/$1"; then
        info "Fetch $1 => $PREBUILTS/bin "
        _curl "bin/$1" "$PREBUILTS/bin/$1" || return 1
        echo -ne "\n"
        chmod a+x "$PREBUILTS/bin/$1"
    # fallback to linux-musl
    elif [[ "$ARCH" == "$(uname -m)-linux-gnu" ]]; then
        warn "Try fetch $1 ($(uname -m)-linux-musl) for $ARCH\n"
        ARCH="$(uname -m)-linux-musl" cmdlet "$@"
    else
        error "Fetch cmdlet $1 ($ARCH) failed\n"
        return 1
    fi
}

# fetch library from server
library() {
    local libname revision

    # shellcheck disable=SC2064
    revision="$(mktemp)" && trap "rm -f $revision" EXIT

    if _curl "$(_revision "$1")" "$revision"; then
        IFS=' ' read -r _ libname _ <<< "$(tail -n1 "$revision")"
        info "Fetch $libname => $PREBUILTS "
        _save "$libname" || return 1
        echo -ne "\n"
        # update pkgconfig .pc
        find "$PREBUILTS/lib/pkgconfig" -name "*.pc" -exec sed -e "s%^prefix=.*$%prefix=$PREBUILTS%p" -i {} \;
    else
        error "Fetch library $1 ($ARCH) failed\n"
        return 1
    fi
}

# fetch package from server
package() {
    local pkgfile pkginfo
    
    # shellcheck disable=SC2064
    pkginfo="$(mktemp)" && trap "rm -f $pkginfo" EXIT

    if _curl "$(_pkginfo "$1")" "$pkginfo"; then
        while read -r record; do
            [ -n "$record" ] || continue
            IFS=' ' read -r _ pkgfile _ <<< "$record"
            info "Fetch $pkgfile => $PREBUILTS "
            _save "$pkgfile" || return 1
            echo -ne "\n"
        done < "$pkginfo"
        # update pkgconfig .pc
        find "$PREBUILTS/lib/pkgconfig" -name "*.pc" -exec sed -e "s%^prefix=.*$%prefix=$PREBUILTS%p" -i {} \;
    else
        error "Fetch package $1 ($ARCH) failed\n"
        return 1
    fi
}

update() {
    local dest tempfile
    if [ -f "$0" ]; then
        dest="$0"
    elif [[ "$PATH" =~ $HOME/.bin ]]; then
        dest="$HOME/.bin/$(basename "${BASE[0]}")"
    else 
        dest="/usr/local/bin/$(basename "${BASE[0]}")"
    fi

    if ! test -w "$(dirname "$dest")"; then
        error "Permission Denied"
        return 1
    fi

    info "Install cmdlets > $dest\n"

    # shellcheck disable=SC2064
    tempfile="$(mktemp)" && trap "rm -f $tempfile" EXIT

    for base in "${BASE[@]}"; do
        info "Try update $_name < $base\n"
        if _curl "$base" "$tempfile"; then
            cp "$tempfile" "$dest"
            chmod a+x "$dest"
            # invoke the new file
            exec "$dest" help
        fi
    done

    error "Update $(basename "$0") failed\n"
    return 1
}

if [ -z "$ARCH" ]; then
    if [ "$(uname -s)" = Darwin ]; then
        ARCH="$(uname -m)-apple-darwin"
    elif test -n "$MSYSTEM"; then
        ARCH="$(uname -m)-msys-${MSYSTEM,,}"
    elif ldd --version | grep -qFw musl; then
        ARCH="$(uname -m)-linux-musl"
    else
        ARCH="$(uname -m)-$OSTYPE"
    fi
fi

# for quick install
if [ "$_name" = "install" ] && [ $# -eq 0 ]; then
    update
elif [ "$_name" = "$(basename "${BASE[0]}")" ]; then
    case "$1" in
        update)
            update
            ;;
        install)    # fetch cmdlets
            for x in "${@:2}"; do
                cmdlet "$x"
                info "Link $x => $0\n"
                ln -sf "$_name" "$WORKDIR/$x"
            done
            ;;
        fetch)      # fetch cmdlets
            for x in "${@:2}"; do
                cmdlet "$x"
            done
            ;;
        library)    # fetch lib files
            for x in "${@:2}"; do
                library "$x"
            done
            ;;
        package)    # fetch package files
            for x in "${@:2}"; do
                package "$x"
            done
            ;;
        help|*)
            usage
            ;;
    esac
else
    # preapre cmdlet
    cmdlet="$PREBUILTS/$_name"
    [ -x "$cmdlet" ] || cmdlet="$PREBUILTS/bin/$_name"
    [ -x "$cmdlet" ] || cmdlet "$_name"

    # exec cmdlet
    cmdlet="$PREBUILTS/$_name"
    [ -x "$cmdlet" ] || cmdlet="$PREBUILTS/bin/$_name"
    [ -x "$cmdlet" ] || error "no cmdlet $_name found.\n"

    exec "$cmdlet" "$@"
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
