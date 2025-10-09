#!/bin/bash -e
#
# shellcheck disable=SC2155

set -eo pipefail
export LANG="${LANG:-en_US.UTF-8}"

VERSION=0.3

WORKDIR="$(dirname "$0" | xargs realpath)"
ARCH="${CMDLETS_ARCH:-}" # auto resolve arch later
PREBUILTS="${CMDLETS_PREBUILTS:-prebuilts}"

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
    else
        ARCH="$(uname -m)-linux-gnu"
    fi
fi

# never resolve symbolic of "$0"
_name="$(basename "$0")"

usage() {
    cat << EOF
$_name $VERSION

Copyright (c) 2025, mtdcy.chen@gmail.com

$_name cmd [args ...]

Options:
    update                  - update $_name
    fetch   <cmdlet>        - fetch cmdlet(s) from server
    install <cmdlet>        - fetch and install cmdlet(s)
    library <libname>       - fetch a library from server
    package <pkgname>       - fetch a package(cmdlets & libraries) from server
    search  <name>          - search for cmdlet, library or package
    help                    - show this help message

Examples:
    $_name install minigzip                 # install the latest version
    $_name install zlib/minigzip@1.3.1      # install the specific version

    $_name package zlib                     # install the latest package
    $_name package zlib@1.3.1               # install the specific version
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
    dest="${2:-$TEMPDIR/$1}"
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
    
    tar -C "$PREBUILTS" -xvf "$TEMPDIR/$1" |
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

# cmdlet v1: cmdlet
_v1() {
    local binfile="bin/$1"

    _exists "$binfile" || return 1

    info1 ">1 Fetch $binfile\n"

    _curl "$binfile" || return 1

    mkdir -p "$PREBUILTS/bin"
    cp -f "$TEMPDIR/$binfile" "$PREBUILTS/bin/$1"
    chmod a+x "$PREBUILTS/bin/$1"
}

# cmdlet v2: cmdlet
_v2() {
    local pkgfile pkginfo 

    pkginfo=$(_revision "$1")

    info2 ">2 Fetch $1 > pkginfo\n"

    _curl "$pkginfo" || return 1

    cat "$TEMPDIR/$pkginfo"

    # v2: sha pkgfile
    IFS=' ' read -r _ pkgfile _ <<< "$(tail -n1 "$TEMPDIR/$pkginfo")"

    info2 ">2 Fetch $1 > $pkgfile\n"

    _flat "$pkgfile" || return 1
}

_manifest() {
    [ -z "$MANIFEST" ] || return 0

    export MANIFEST="$PREBUILTS/cmdlets.manifest"

    # pull manifest first
    info3 ">> Fetch manifest\n"
    _curl "$(basename "$MANIFEST")" "$MANIFEST" || {
        warn "<< Fetch manifest failed\n"
        touch "$MANIFEST"
    }
}

# search manifest, return multi-line results
_search() {
    # cmdlets:
    #   minigzip
    #   zlib/minigzip@1.3.1
    # packages:
    #   zlib
    #   zlib@1.3.1

    local pkgname pkgfile pkgver

    IFS='@' read -r pkgname pkgver  <<< "$1"
    IFS='/' read -r pkgname pkgfile <<< "$pkgname"

    # v3: no latest support
    [ "$pkgver" = "latest" ] && unset pkgver || true

    if test -n "$pkgfile"; then
        grep " $pkgname/$pkgfile@$pkgver" "$MANIFEST"
    else
        grep "^$pkgname .*/.*@$pkgver\|^$pkgname@$pkgver\| $pkgname/.*@$pkgver\| .*/$pkgname@$pkgver" "$MANIFEST"
    fi | sort -u
}

# cmdlet v3/manifest: cmdlet [pkgname]
_v3() {
    local pkgname pkgfile
    
    _manifest

    test -n "$2" && pkgname="$2/$1" || pkgname="$1"

    IFS=' ' read -r _ pkgfile _ < <( _search "$pkgname" | tail -n 1 )

    [ -n "$pkgfile" ] || return 1

    info3 ">3 Fetch $1 > $pkgfile\n"

    # v3 git repo do not have file hierarchy
    _flat "$pkgfile" || 
    _flat "$(basename "$pkgfile")" || 
    return 1
}

# v3 only
search() {
    _manifest

    info3 ">3 Search $1\n"

    while read -r line; do
        info3 "=> $line\n"
    done < <( _search "$1" )
}

# fetch cmdlet
cmdlet() {
    # for cmdlet, v1 > v3 > v2
    if _v1 "$@" || _v3 "$@" || _v2 "$@"; then
        true
    # fallback to linux-musl
    #elif [[ "$ARCH" == "$(uname -m)-linux-gnu" ]]; then
    #    warn "-- Fetch $1/$(uname -m)-linux-musl for $ARCH again\n"
    #    ARCH="$(uname -m)-linux-musl" cmdlet "$@"
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
    local pkgname pkgver pkgfile pkginfo parts

    _manifest
   
    # zlib@1.3.1
    IFS='@' read -r pkgname pkgver <<< "$1"

    # cmdlet v3/manifest
    if test -n "$pkgver" && [ "$pkgver" != latest ]; then
        IFS=' ' read -r -a parts <<< "$(grep " $pkgname/.*@$pkgver" "$MANIFEST" | awk '{print $2}' | xargs)"
    else
        IFS=' ' read -r -a parts <<< "$(grep " $pkgname/"           "$MANIFEST" | awk '{print $1}' | sort -u | xargs)"
    fi

    if test -n "${parts[*]}"; then
        info3 "\n#3 package $pkgname > ${parts[*]}\n"
        for part in "${parts[@]}"; do 
            _v3 "$part" "$pkgname" || {
                error "<< fetch $part/$ARCH failed\n"
                return 1
            }
        done

        _fix_pc
        touch "$PREBUILTS/.$pkgname.d" # mark as ready
        return 0
    fi

    info2 "\n#2 package $1\n"

    [ -n "$pkgver" ] || pkgver=latest
    pkginfo="$pkgname@$pkgver"

    if _curl "$pkginfo"; then
        cat "$TEMPDIR/$pkginfo"

        while read -r pkgfile; do
            [ -n "$pkgfile" ] || continue
            IFS=' ' read -r _ pkgfile _ <<< "$pkgfile"
            info2 ">2 Fetch $1 > $pkgfile\n"
            _flat "$pkgfile" || {
                error "<< fetch $pkgfile/$ARCH failed\n"
                return 1
            }
        done < "$TEMPDIR/$pkginfo"
        touch "$PREBUILTS/.$1.d" # mark as ready
    else
        error "<< Fetch package $1/$ARCH failed\n"
        return 1
    fi

    _fix_pc
}

update() {
    local target
    if [ -f "$0" ]; then
        target="$0"
    elif [[ "$PATH" =~ $HOME/.bin ]]; then
        target="$HOME/.bin/$_name"
    elif [[ "$PATH" =~ $HOME/.local/bin ]]; then
        target="$HOME/.local/bin/$_name"
    else 
        target="/usr/local/bin/$_name"
    fi

    if ! test -w "$(dirname "$target")"; then
        error "<< Permission Denied\n"
        return 1
    fi

    for base in "${BASE[@]}"; do
        info ">> Fetch $_name < $base\n"
        if _curl "$base" "$TEMPDIR/$_name"; then
            info "-- $_name > $target\n"
            cp "$TEMPDIR/$_name" "$target"
            chmod a+x "$target"
            # invoke the new file
            exec "$target" help
        fi
    done

    error "<< Update $(basename "$0") failed\n"
    return 1
}

# link file [alias...]
_link() {
    info "-- Link $1 => $PREBUILTS/bin/$1\n"

    ln -sf "$PREBUILTS/bin/$1" "$WORKDIR/$1"

    for alias in "${@:2}"; do
        info "-- Link $alias => $1\n"
        ln -sf "$1" "$WORKDIR/$alias"
    done
}

# for quick install
if [ "$_name" = "install" ] && [ $# -eq 0 ]; then
    update
elif [ "$_name" = "$(basename "${BASE[0]}")" ]; then
    # shellcheck disable=SC2064
    TEMPDIR="$(mktemp -d)" && trap "rm -rf $TEMPDIR" EXIT

    case "$1" in
        update) update; exit 0 ;;
        help)   usage;  exit 0 ;;
    esac

    cd "$WORKDIR"

    case "$1" in
        manifest)
            _manifest
            cat "$MANIFEST"
            ;;
        search)
            search "$2"
            ;;
        install)    # install cmdlets
            for x in "${@:2}"; do
                IFS=':' read -r bin alias <<< "$x"
                cmdlet "$bin" || ret=$?

                bin="$(basename "$bin")"

                _link "$bin" ${alias//:/ }
            done
            ;;
        fetch)      # fetch cmdlets
            for x in "${@:2}"; do
                cmdlet "$x" || ret=$?
            done
            ;;
        library)    # fetch lib files
            for x in "${@:2}"; do
                library "$x" || ret=$?
            done
            ;;
        package)    # fetch package files
            for x in "${@:2}"; do
                package "$x" || ret=$?
            done
            ;;
        *)
            usage
            ;;
    esac
    exit $ret
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
