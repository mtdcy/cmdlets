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

error() { echo -e "\\033[31m$*\\033[39m" 1>&2; }
info()  { echo -e "\\033[32m$*\\033[39m" 1>&2; }
warn()  { echo -e "\\033[33m$*\\033[39m" 1>&2; }
info1() { echo -e "\\033[35m$*\\033[39m" 1>&2; }
info2() { echo -e "\\033[34m$*\\033[39m" 1>&2; }
info3() { echo -e "\\033[36m$*\\033[39m" 1>&2; }

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

# search manifest for package
#  input: name [--pkgname] [--pkgfile] [--any]
#  output: multi-line match results
_search() {
    _manifest &>/dev/null

    # cmdlets:
    #   minigzip
    #   minigzip@1.3.1
    #   zlib/minigzip@1.3.1
    # packages:
    #   zlib
    #   zlib@1.3.1

    local pkgname pkgfile pkgver

    IFS='@' read -r pkgfile pkgver  <<< "$1"

    # v3: no latest support
    [ "$pkgver" = "latest" ] && unset pkgver || true

    # pkgname exists?
    [[ "$pkgfile" =~ / ]] && IFS='/' read -r pkgname pkgfile <<< "$pkgfile"

    options=( "${@:2}" )
    test -n "${options[*]}" || options=( --pkgfile --pkgname )

    for opt in "${options[@]}"; do
        case "$opt" in
            --pkgfile)
                grep "^$pkgfile@?$pkgver \|/$pkgfile@$pkgver" "$MANIFEST" || true
                ;;
            --pkgname)
                grep " ${pkgname:-$pkgfile}/.*@$pkgver" "$MANIFEST" || true
                ;;
            --any)
                grep -F "$1" "$MANIFEST" || true
                ;;
        esac
    done | uniq
}

# cmdlet v3/manifest
#  input: pkgfile [pkgname] [options]
#  output: return 0 on success
_v3() {
    local pkgfile pkgname
    
    test -n "$2" && pkgname="$2/$1" || pkgname="$1"

    IFS=' ' read -r _ pkgfile _ < <( _search "$pkgname" "${@:3}" | tail -n 1 )

    [ -n "$pkgfile" ] || return 1

    info3 ">3 Fetch $1 < $pkgfile"

    # v3 git repo do not have file hierarchy
    _unzip "$pkgfile" || 
    _unzip "$(basename "$pkgfile")" || 
    return 1
}

# v3 only
search() {
    _manifest &>/dev/null

    info3 ">3 Search $*"

    _search "$@" | sed 's/^/=> /'
}

# fetch cmdlet: name [options]
#  input: name [--install [links...] ]
#  output: return 0 on success
fetch() {
    _manifest &>/dev/null

    if _v3 "$1" "" --pkgfile || _v2 "$1" || _v1 "$1"; then
        true
    else
        error "<< Fetch $1/$ARCH failed"
        return 1
    fi

    # target with or without version
    test -f "$PREBUILTS/bin/$1" && target="$1" || target="${1%%@*}"

    shift 1
    while [ $# -gt 0 ]; do
        case "$1" in
            --install)
                # cmdlets.sh install bash@3.2:bash
                info "== Install $target => $PREBUILTS/bin/$target"
                ln -sf "$PREBUILTS/bin/$target" "$target"

                local links=( ${2//:/ } )

                if [ ${#links[@]} -gt 0 ]; then
                    info "== Install links"
                    for link in "${links[@]}"; do
                        [ "$link" = "$target" ] && continue
                        echo "=> $link => $target"
                        ln -sf "$target" "$link"
                    done
                else
                    info "== Install default links"
                    while read -r link; do
                        [ "$(readlink "$link")" = "$target" ] || continue

                        link="$(basename "$link")"
                        echo "=> $link => $target"
                        ln -sf "$target" "$link"
                    done < <(find "$PREBUILTS/bin" -type l)
                fi

                shift 1
                ;;
        esac
        shift 1
    done
}

# remove cmdlets
#  input: name
remove() {
    local target="$1"

    info "=> remove $1"

    if ! test -L "$target"; then
        error "-- $target not exists"
        return 1
    fi

    while read -r link; do
        [ "$(readlink "$link")" = "$target" ] || continue
        echo "-- $link"
        rm -f "$link"
    done < <(find "$(pwd -P)" -maxdepth 1 -type l)

    while read -r link; do
        [ "$(readlink "$link")" = "$target" ] || continue

        echo "-- $link"
        rm -f "$link"
    done < <(find "$(pwd -P)/$PREBUILTS/bin" -type l)

    echo "-- $(pwd -P)/$PREBUILTS/bin/$target"
    rm -f "$PREBUILTS/bin/$target"

    echo "-- $(pwd -P)/$target"
    rm -f "$target"
}

_fix_pc() {
    find "$PREBUILTS/lib/pkgconfig" -name "*.pc" -exec \
        sed -i "s%^prefix=.*$%prefix=$PREBUILTS%g" {} \;
} 2>/dev/null

# fetch package
package() {
    _manifest &>/dev/null

    local pkgname pkgver pkgfile pkginfo

    # zlib@1.3.1
    IFS='@' read -r pkgname pkgver <<< "$1"

    # cmdlet v3/manifest
    IFS=' ' read -r -a pkgfile < <( _search "$1" --pkgname | awk '{print $1}' | uniq | xargs )

    if test -n "${pkgfile[*]}"; then
        info3 "#3 Fetch package $1 < ${pkgfile[*]}"

        for file in "${pkgfile[@]}"; do 
            _v3 "$file" "$pkgname" --pkgfile || {
                error "<< Fetch package $file/$ARCH failed"
                return 1
            }
        done

        touch "$PREBUILTS/.$pkgname.d" # mark as ready
        return 0
    fi

    info2 "#2 Fetch package $1"

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

# list installed cmdlets
list() {
    local width link real
    info "== List installed cmdlets"

    width="$(find . -type l | wc -L)"

    while read -r link; do
        real="$(readlink "$link")"
        [[ "$real" =~ ^"$PREBUILTS" ]] || test -L "$real" || continue
        printf "%${width}s => %s\n" "$(basename "$link")" "$real"
    done < <(find . -type l)
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
            if test -n "$2"; then
                fetch "$2" || ret=$?
            else
                update
            fi
            ;;
        search)
            search "${@:2}"
            ;;
        install)
            IFS=':' read -r bin alias <<< "$2"
            fetch "$bin" --install "$alias" || ret=$?
            ;;
        remove)
            remove "$2" || ret=$?
            ;;
        list)
            list
            ;;
        fetch)      # fetch cmdlets
            for x in "${@:2}"; do
                fetch "$x" || ret=$?
            done
            ;;
        package)    # fetch package files
            for x in "${@:2}"; do
                package "$x" || ret=$?
            done
            _fix_pc
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
