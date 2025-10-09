#!/usr/bin/env bash
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

NAME="$(basename "${BASE[0]}")"

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

usage() {
    cat << EOF
$NAME $VERSION

Copyright (c) 2025, mtdcy.chen@gmail.com

$NAME cmd [args ...]

Options:
    update                  - update $NAME
    fetch   <cmdlet>        - fetch cmdlet(s) from server
    install <cmdlet>        - fetch and install cmdlet(s)
    library <libname>       - fetch a library from server
    package <pkgname>       - fetch a package(cmdlets & libraries) from server
    search  <name>          - search for cmdlet, library or package
    help                    - show this help message

Examples:
    $NAME install minigzip                  # install the latest version
    $NAME install zlib/minigzip@1.3.1       # install the specific version

    $NAME package zlib                      # install the latest package
    $NAME package zlib@1.3.1                # install the specific version
EOF
}

error() { echo -e "\\033[31m$*\\033[39m";   }
info()  { echo -e "\\033[32m$*\\033[39m";   }
warn()  { echo -e "\\033[33m$*\\033[39m";   }
info1() { echo -e "\\033[35m$*\\033[39m";   }
info2() { echo -e "\\033[34m$*\\033[39m";   }
info3() { echo -e "\\033[36m$*\\033[39m";   }

# is file existing in repo
_exists() (
    local source
    for repo in "${REPO[@]}"; do
        [[ "$1" =~ ^https?:// ]] && source="$1" || source="$repo/$ARCH/$1"
        curl -sI "${CURL_OPTS[@]}" "$source" -o /dev/null && return 0 || true
    done
    return 1
)

# curl file to destination or TEMPDIR
_curl() (
    local source dest
    dest="${2:-$TEMPDIR/$1}"
    mkdir -p "$(dirname "$dest")"
    for repo in "${REPO[@]}"; do
        [[ "$1" =~ ^https?:// ]] && source="$1" || source="$repo/$ARCH/$1"
        info "== $source"
        curl -sI "${CURL_OPTS[@]}" "$source" -o /dev/null || continue
        echo "=> ${2:-$1}"
        curl -S  "${CURL_OPTS[@]}" "$source" -o "$dest" && return 0 || true
    done
    return 1
)

# save package to PREBUILTS
_unzip() (
    test -f "$1" || _curl "$1" || return 1
    
    tar -C "$PREBUILTS" -xvf "$TEMPDIR/$1" | sed 's/^/=> /'
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

    info1 ">1 Fetch $binfile"

    _curl "$binfile" || return 1

    mkdir -p "$PREBUILTS/bin"

    cp -f "$TEMPDIR/$binfile" "$PREBUILTS/bin/$1"
    chmod a+x "$PREBUILTS/bin/$1"
}

# cmdlet v2: cmdlet
_v2() {
    local pkgfile pkginfo 

    pkginfo=$(_revision "$1")

    info2 ">2 Fetch $1 < pkginfo"

    _curl "$pkginfo" || return 1

    cat "$TEMPDIR/$pkginfo"

    # v2: sha pkgfile
    IFS=' ' read -r _ pkgfile _ <<< "$(tail -n1 "$TEMPDIR/$pkginfo")"

    info2 ">2 Fetch $1 < $pkgfile"

    _unzip "$pkgfile" || return 1
}

_manifest() {
    [ -z "$MANIFEST" ] || return 0

    export MANIFEST="$PREBUILTS/cmdlets.manifest"

    # pull manifest first
    info3 ">> Fetch manifest"
    _curl "$(basename "$MANIFEST")" "$MANIFEST" || {
        warn "<< Fetch manifest failed"
        touch "$MANIFEST"
    }
}

# search manifest, return multi-line results
_search() {
    _manifest 1>&2

    # cmdlets:
    #   minigzip
    #   minigzip@1.3.1
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
        grep "^$pkgname .*/.*@$pkgver\|^$pkgname@$pkgver \| $pkgname/.*@$pkgver\| .*/$pkgname@$pkgver" "$MANIFEST"
    fi
}

# cmdlet v3/manifest: cmdlet [pkgname]
_v3() {
    local pkgname pkgfile
    
    test -n "$2" && pkgname="$2/$1" || pkgname="$1"

    IFS=' ' read -r _ pkgfile _ < <( _search "$pkgname" | tail -n 1 )

    [ -n "$pkgfile" ] || return 1

    info3 ">3 Fetch $1 < $pkgfile"

    # v3 git repo do not have file hierarchy
    _unzip "$pkgfile" || 
    _unzip "$(basename "$pkgfile")" || 
    return 1
}

# v3 only
search() {
    _manifest && echo ""

    info3 ">3 Search $1"

    _search "$1" | sed 's/^/=> /'
}

# fetch cmdlet
cmdlet() {
    _manifest && echo ""

    local ver 
    IFS='@' read -r _ ver <<< "$*"

    # for cmdlet, v1 > v3 > v2
    if test -z "$ver" && _v1 "$@"; then
        true;
    elif _v3 "$@" || _v2 "$@"; then
        true
    # fallback to linux-musl
    #elif [[ "$ARCH" == "$(uname -m)-linux-gnu" ]]; then
    #    warn "-- Fetch $1/$(uname -m)-linux-musl for $ARCH again"
    #    ARCH="$(uname -m)-linux-musl" cmdlet "$@"
    else
        error "<< Fetch $1/$ARCH failed"
        return 1
    fi
}

_fix_pc() {
    find "$PREBUILTS/lib/pkgconfig" -name "*.pc" -exec \
        sed -i "s%^prefix=.*$%prefix=$PREBUILTS%g" {} \;
} 2>/dev/null

# fetch library from server
library() {
    _manifest && echo ""

    # cmdlet v3/manifest
    if _v3 "$@" || _v2 "$@"; then
        touch "$PREBUILTS/.$1.d" # mark as ready
        _fix_pc
    else
        error "<< Fetch $1/$ARCH failed"
        return 1
    fi
}

# fetch package
package() {
    _manifest && echo ""

    local pkgname pkgver pkgfile pkginfo

    # zlib@1.3.1
    IFS='@' read -r pkgname pkgver <<< "$1"

    # cmdlet v3/manifest
    IFS=' ' read -r -a pkgfile < <( _search "$1" | awk '{print $1}' | uniq | xargs )

    if test -n "${pkgfile[*]}"; then
        info3 "#3 Fetch package $1 < ${pkgfile[*]}"

        for file in "${pkgfile[@]}"; do 
            _v3 "$file" "$pkgname" || {
                error "<< Fetch package $file/$ARCH failed"
                return 1
            }
        done

        _fix_pc
        touch "$PREBUILTS/.$pkgname.d" # mark as ready
        return 0
    fi

    info2 "#2 fetch package $1"

    [ -n "$pkgver" ] || pkgver=latest
    pkginfo="$pkgname@$pkgver"

    if _curl "$pkginfo"; then
        cat "$TEMPDIR/$pkginfo"

        while read -r pkgfile; do
            [ -n "$pkgfile" ] || continue

            # sha pkgfile
            IFS=' ' read -r _ pkgfile _ <<< "$pkgfile"

            info2 ">2 Fetch $pkgfile"

            _unzip "$pkgfile" || {
                error "<< fetch package $pkgfile/$ARCH failed"
                return 1
            }
        done < "$TEMPDIR/$pkginfo"

        touch "$PREBUILTS/.$1.d" # mark as ready
    else
        error "<< Fetch package $1/$ARCH failed"
        return 1
    fi

    _fix_pc
}

update() {
    local target
    if [ -f "$0" ]; then
        target="$0"
    elif [[ "$PATH" =~ $HOME/.bin ]]; then
        target="$HOME/.bin/$NAME"
    elif [[ "$PATH" =~ $HOME/.local/bin ]]; then
        target="$HOME/.local/bin/$NAME"
    else 
        target="/usr/local/bin/$NAME"
    fi

    if ! mkdir -p "$(dirname "$target")"; then
        error "<< Permission Denied?"
        return 1
    fi

    for base in "${BASE[@]}"; do
        info ">> Fetch $NAME < $base"
        if _curl "$base" "$TEMPDIR/$NAME"; then
            info "-- $NAME > $target"
            cp "$TEMPDIR/$NAME" "$target"
            chmod a+x "$target"
            # invoke the new file
            exec "$target" help
        fi
    done

    error "<< Update $(basename "$0") failed"
    return 1
}

# link file [alias...]
_link() {
    local bin="$1"

    # cmdlets.sh install find@0.8.0:bash
    test -f "$PREBUILTS/bin/$1" || IFS='@' read -r bin _ <<< "$bin"

    info "-- Link $bin => $PREBUILTS/bin/$bin"
    ln -sf "$PREBUILTS/bin/$bin" "$WORKDIR/$bin"

    for alias in "${@:2}"; do
        [ "$alias" = "$bin" ] && continue
        info "-- Link $alias => $bin"
        ln -sf "$bin" "$WORKDIR/$alias"
    done
}

# invoke cmd [args...]
invoke() {
    cd "$WORKDIR"

    # shellcheck disable=SC2064
    TEMPDIR="$(mktemp -d)" && trap "rm -rf $TEMPDIR" EXIT

    local ret=0
    case "$1" in
        manifest)
            _manifest
            cat "$MANIFEST"
            ;;
        update)
            update
            ;;
        search)
            for x in "${@:2}"; do
                search "$x"
            done
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
    exit $?
}

# never resolve symbolic of "$0"
_name="$(basename "$0")"

# for quick install
if [ "$_name" = "install" ] && [ $# -eq 0 ]; then
    invoke update
elif [ "$_name" = "$NAME" ]; then
    invoke "$@"
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
