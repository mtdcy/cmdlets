#!/bin/bash -e
#
# shellcheck disable=SC2155

set -eo pipefail
export LANG="${LANG:-en_US.UTF-8}"

VERSION=0.3

WORKDIR="$(dirname "$0" | xargs realpath)"
ARCH="${CMDLETS_ARCH:-}" # auto resolve arch later
PREBUILTS="${CMDLETS_PREBUILTS:-$WORKDIR/prebuilts}"
MANIFEST="$PREBUILTS/cmdlets.manifest"

unset CMDLETS_ARCH CMDLETS_PREBUILTS

REPO=(
    # v3 & v2 & v1
    "${CMDLETS_MAIN_REPO:-https://pub.mtdcy.top/cmdlets/latest}"
    # v3/git
    https://github.com/mtdcy/cmdlets/releases/download
    # cmdlets is mainly for private use, so put the public repo at last.
)

# remove duplicated repo url
IFS=' ' read -r -a REPO <<< "$(printf "%s\n" "${REPO[@]}" | uniq | xargs)"

BASE=(
    "https://git.mtdcy.top/mtdcy/cmdlets/raw/branch/main/cmdlets.sh"
    "https://raw.githubusercontent.com/mtdcy/cmdlets/main/cmdlets.sh"
)

CURL_OPTS=( -L --fail --connect-timeout 1 --progress-bar --no-progress-meter )

if [ -z "$ARCH" ]; then
    if [ "$(uname -s)" = Darwin ]; then
        ARCH="$(uname -m)-apple-darwin"
    elif test -n "$MSYSTEM"; then
        ARCH="$(uname -m)-msys-${MSYSTEM,,}"
    elif ldd --version 2>/dev/null | grep -qFw musl; then
        ARCH="$(uname -m)-linux-musl"
    else
        ARCH="$(uname -m)-$OSTYPE"
    fi
fi

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
info1() { echo -ne "\\033[35m$*\\033[39m"; }
info2() { echo -ne "\\033[34m$*\\033[39m"; }
info3() { echo -ne "\\033[36m$*\\033[39m"; }

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
    local source dest
    dest="${2:-$PREBUILTS/$1}"
    mkdir -p "$(dirname "$dest")"
    for repo in "${REPO[@]}"; do
        [[ "$1" =~ ^https?:// ]] && source="$1" || source="$repo/$ARCH/$1"
        info "== $source\n"
        curl -sI "${CURL_OPTS[@]}" "$source" -o /dev/null || continue
        echo "=> $dest"
        curl -S  "${CURL_OPTS[@]}" "$source" -o "$dest" && return 0 || true
    done
    return 1
)

# save package to PREBUILTS
_flat() (
    _curl "$1" || return 1
    
    tar -C "$PREBUILTS" -xvf "$PREBUILTS/$1" |
    while read -r line; do
        echo -en "=> $PREBUILTS/$line\n"
    done
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

# cmdlet v1: cmdlet
_v1() {
    local binfile="bin/$1"

    _exists "$binfile" || return 1

    info1 ">> Fetch $binfile\n"

    _curl "$binfile" || return 1
    chmod a+x "$PREBUILTS/bin/$1"
}

# cmdlet v2: cmdlet
_v2() {
    local pkgfile pkginfo 

    pkginfo=$(_revision "$1")

    info2 ">> Fetch $1 > pkginfo\n"

    _curl "$pkginfo" || return 1

    cat "$PREBUILTS/$pkginfo"

    # v2: sha pkgfile
    IFS=' ' read -r _ pkgfile _ <<< "$(tail -n1 "$PREBUILTS/$pkginfo")"

    info2 ">> Fetch $1 > $pkgfile\n"

    _flat "$pkgfile" || return 1
}

# cmdlet v3/manifest: cmdlet [pkgname]
_v3() {
    local pkgfile

    # v3: cmdlet pkgname/pkgfile.tar.gz sha
    IFS=' ' read -r _ pkgfile _ < <({
        [ -n "$2" ] &&
        grep "^$1 $2/"  "$MANIFEST" ||
        grep "^$1 "     "$MANIFEST" ||
        grep " $1\|/$1" "$MANIFEST"
    } | tail -n 1)

    [ -n "$pkgfile" ] || return 1

    info3 ">> Fetch $1 > $pkgfile\n"

    # v3 git repo do not have file hierarchy
    _flat "$pkgfile" || 
    _flat "$(basename "$pkgfile")" || 
    return 1
}

# fetch cmdlet
cmdlet() {
    if _v3 "$@" || _v2 "$@" || _v1 "$@"; then
        true
    # fallback to linux-musl
    elif [[ "$ARCH" == "$(uname -m)-linux-gnu" ]]; then
        warn "-- Fetch $1/$(uname -m)-linux-musl for $ARCH again\n"
        ARCH="$(uname -m)-linux-musl" cmdlet "$@"
    else
        error "<< Fetch $1/$ARCH failed\n"
        return 1
    fi
}

_fix_pc() {
    find "$PREBUILTS/lib/pkgconfig" -name "*.pc" -exec \
        sed -i "s%^prefix=.*$%prefix=$PREBUILTS%g" {} \;
} 2>/dev/null

# fetch library from server
library() {
    # cmdlet v3/manifest
    if _v3 "$@" || _v2 "$@"; then
        touch "$PREBUILTS/.$1.d" # mark as ready
        _fix_pc
    else
        error "<< Fetch $1/$ARCH failed\n"
        return 1
    fi
}

# fetch package
package() {
    local pkgfile pkginfo parts

    # cmdlet v3/manifest
    IFS=' ' read -r -a parts <<< "$(grep -F " $1/" "$MANIFEST" | awk '{print $1}' | sort -u | xargs)"

    if test -n "${parts[*]}"; then
        info3 "\n## package $1 > ${parts[*]}\n"
        for part in "${parts[@]}"; do 
            _v3 "$part" "$1" || {
                error "<< fetch $part/$ARCH failed\n"
                return 1
            }
        done

        _fix_pc
        touch "$PREBUILTS/.$1.d" # mark as ready
        return 0
    fi

    info2 "\n## package $1\n"

    pkginfo="$(_pkginfo "$1")"

    if _curl "$pkginfo"; then
        cat "$PREBUILTS/$pkginfo"

        while read -r pkgfile; do
            [ -n "$pkgfile" ] || continue
            IFS=' ' read -r _ pkgfile _ <<< "$pkgfile"
            info2 ">> Fetch $1 > $pkgfile\n"
            _flat "$pkgfile" || {
                error "<< fetch $pkgfile/$ARCH failed\n"
                return 1
            }
        done < "$PREBUILTS/$pkginfo"
        touch "$PREBUILTS/.$1.d" # mark as ready
    else
        error "<< Fetch package $1/$ARCH failed\n"
        return 1
    fi

    _fix_pc
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
        error "<< Permission Denied\n"
        return 1
    fi

    # shellcheck disable=SC2064
    tempfile="$(mktemp)" && trap "rm -f $tempfile" EXIT

    for base in "${BASE[@]}"; do
        info ">> Fetch $_name < $base\n"
        if _curl "$base" "$tempfile"; then
            info "-- cmdlets > $dest\n"
            cp "$tempfile" "$dest"
            chmod a+x "$dest"
            # invoke the new file
            exec "$dest" help
        fi
    done

    error "<< Update $(basename "$0") failed\n"
    return 1
}

# for quick install
if [ "$_name" = "install" ] && [ $# -eq 0 ]; then
    update
elif [ "$_name" = "$(basename "${BASE[0]}")" ]; then
    # pull manifest first
    info3 ">> Fetch manifest\n"
    _curl "$(basename "$MANIFEST")" "$MANIFEST" || {
        warn "<< Fetch manifest failed\n"
        touch "$MANIFEST"
    }

    case "$1" in
        manifest)
            cat "$MANIFEST"
            ;;
        update)
            update
            ;;
        install)    # install cmdlets
            for x in "${@:2}"; do
                IFS=':' read -r bin alias <<< "$x"
                cmdlet "$bin"

                bin="$(basename "$bin")"
                info "-- Link $bin => $_name\n"
                ln -sf "$_name" "$WORKDIR/$bin"

                # create alias links
                if [ -n "$alias" ]; then
                    IFS=':' read -r -a alias <<< "$alias"
                    for a in "${alias[@]}"; do
                        info "-- Link $a => $bin\n"
                        # double links
                        ln -sf "$bin" "$PREBUILTS/bin/$a"
                        ln -sf "$bin" "$WORKDIR/$a"
                    done
                fi
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
    [ -f "$cmdlet" ] || cmdlet="$PREBUILTS/bin/$_name"
    [ -f "$cmdlet" ] || cmdlet "$_name"

    # exec cmdlet
    cmdlet="$PREBUILTS/$_name"
    [ -f "$cmdlet" ] || cmdlet="$PREBUILTS/bin/$_name"
    [ -f "$cmdlet" ] || error "no cmdlet $_name found.\n"

    # fix permission
    [ -x "$cmdlet" ] || chmod a+x "$cmdlet"

    exec "$cmdlet" "$@"
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
