#!/usr/bin/env bash
#
# shellcheck disable=SC2155

set -eo pipefail
export LANG="${LANG:-en_US.UTF-8}"

VERSION=1.0-alpha

API="${CMDLETS_API:-v3}"
ARCH="${CMDLETS_ARCH:-}" # auto resolve arch later
PREBUILTS="${CMDLETS_PREBUILTS:-prebuilts}"

unset CMDLETS_API CMDLETS_ARCH CMDLETS_PREBUILTS

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

Usage: $NAME cmd [args ...]

Options:
    update                  - update $NAME
    update  <cmdlet>        - update cmdlet

    list                    - list installed cmdlets
    search  <name>          - search for cmdlet, library or package
    install <cmdlet>        - fetch and install cmdlet
    remove  <cmdlet>        - remove cmdlet

    help                    - show this help message

    (for developers)
    fetch   <cmdlet ...>    - fetch cmdlet(s)
    package <pkgname ...>   - fetch package(s) (cmdlets & libraries)

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

# prepend each line with '=> '
_details() {
    sed 's/^/=> /'
}

_details_escape() {
    sed 's/^/=> /' | xargs
}

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
        info "== curl < $source"
        curl -sI "${CURL_OPTS[@]}" "$source" -o /dev/null || continue
        echo ">> ${2:-$1}"
        curl -S  "${CURL_OPTS[@]}" "$source" -o "$dest" && return 0 || true
    done
    return 1
)

# save package to PREBUILTS
_unzip() (
    test -f "$1" || _curl "$1" || return 1
    
    tar -C "$PREBUILTS" -xvf "$TEMPDIR/$1" | tee -a "$TEMPDIR/files" | _details
)

# cmdlet v1
#  input: path/to/file
_v1() {
    local name="$1"

    [[ "$name" =~ / ]] || name="bin/$name"

    _exists "$name" || return 1

    info1 "#1 Fetch $name"

    _curl "$name" || return 2

    mkdir -p "$PREBUILTS/$(dirname "$name")"

    cp -f "$TEMPDIR/$name" "$PREBUILTS/$name"

    chmod a+x "$PREBUILTS/$name"

    echo "$name" > "$TEMPDIR/files"
}

# cmdlet v2:
#  input: name
_v2() {
    [ "$API" != "v1" ] || return 127

    local pkgfile pkgver pkginfo 

    # zlib
    # zlib@1.3.1
    # zlib/minigzip@1.3.1
    IFS='@' read -r pkgfile pkgver <<< "$1"

    test -n "$pkgver" || pkgver="latest"

    pkginfo="$pkgfile@$pkgver"

    info2 "#2 Fetch $1 < $pkginfo"

    _curl "$pkginfo" || return 1

    cat "$TEMPDIR/$pkginfo" | _details

    # v2: sha pkgfile
    IFS=' ' read -r _ pkgfile _ < <(tail -n1 "$TEMPDIR/$pkginfo")

    info2 "#2 Fetch $1 < $pkgfile"

    _unzip "$pkgfile" || return 2
}

_manifest() {
    [ -z "$MANIFEST" ] || return 0

    export MANIFEST="$PREBUILTS/cmdlets.manifest"

    # pull manifest first
    info3 "== Fetch manifest"
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

    set -x
    for opt in "${options[@]}"; do
        case "$opt" in
            --pkgfile)
                if test -n "$pkgver"; then
                    grep "^$pkgfile@$pkgver \|/$pkgfile@$pkgver" "$MANIFEST" || true
                else
                    grep "^$pkgfile " "$MANIFEST" || true
                fi
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
    [ "$API" = "v3" ] || return 127

    local pkgfile="$1"
    test -z "$2" || pkgfile="$2/$pkgfile"

    # name file sha
    IFS=' ' read -r _ pkgfile _ < <( _search "$pkgfile" "${@:3}" | tail -n 1 )

    test -n "$pkgfile" || return 1

    info3 "#3 Fetch $1 < $pkgfile"

    # v3 git repo do not have file hierarchy
    _unzip "$pkgfile" || 
    _unzip "$(basename "$pkgfile")" || 
    return 1
}

# v3 only
search() {
    _manifest &>/dev/null

    info3 "#3 Search $*"

    _search "$@" | _details
}

# fetch cmdlet: name [options]
#  input: name [--install [links...] ]
#  output: return 0 on success
fetch() {
    _manifest &>/dev/null

    true > "$TEMPDIR/files"

    if _v3 "$1" "" --pkgfile || _v2 "$1" || _v1 "$1"; then
        true
    else
        error "<< Fetch $1/$ARCH failed"
        return 1
    fi

    # target with or without version
    target="$(basename "$1")"
    test -f "$PREBUILTS/bin/$target" || target="${target%%@*}"

    shift 1
    while [ $# -gt 0 ]; do
        case "$1" in
            --install)
                if test -n "$2"; then
                    # cmdlets.sh install bash@3.2:bash@3.2:bash
                    info "== Install target and link(s)"

                    local links=( ${2//:/ } )
                    local width=$( printf 'bin/%s\n' "$target" "${links[@]}" | wc -L )

                    printf "%${width}s -> %s\n" "$target" "$PREBUILTS/bin/$target"
                    ln -sf "$PREBUILTS/bin/$target" "$target"

                    for link in "${links[@]//*\//}"; do
                        [ "$link" = "$target" ] && continue
                        printf "%${width}s -> %s\n" "$link" "$target"
                        ln -sf "$target" "$link"
                    done
                elif test -s "$TEMPDIR/files"; then
                    info "== Install target(s)"
                    local width=$(wc -L < "$TEMPDIR/files")

                    while read -r file; do
                        if test -L "$file"; then
                            printf "%${width}s -> %s\n" "$(basename "$file")" "$(readlink "$file")"
                            mv -f "$file" .
                        else
                            printf "%${width}s -> %s\n" "$(basename "$file")" "$file"
                            ln -sf "$file" .
                        fi
                    done < <(cat "$TEMPDIR/files" | sed "s%^%$PREBUILTS/%")
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

    info "== remove $target"

    while read -r link; do
        rm -fv "$link" | _details_escape
    done < <( find . -type l -lname "$target" -printf '%P\n' )

    while read -r file; do
        rm -fv "$file" | _details_escape
    done < <( find . -name "$target" -printf '%P\n' )
}

# fetch package
package() {
    _manifest &>/dev/null

    local pkgname pkgver pkgfile pkginfo

    # zlib@1.3.1
    IFS='@' read -r pkgname pkgver <<< "$1"

    # cmdlet v3/manifest
    if [ "$API" = "v3" ]; then
        IFS=' ' read -r -a pkgfile < <( _search "$1" --pkgname | awk '{print $1}' | sort -u | xargs )

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
        else
            error "<< Fetch package $1/$ARCH failed"
            return 1
        fi
    fi

    info2 "#2 Fetch package $1"

    [ -n "$pkgver" ] || pkgver=latest

    pkginfo="$pkgname/pkginfo@$pkgver"

    if ! _curl "$pkginfo"; then
        error "<< Fetch $pkginfo failed"
        return 1
    fi

    cat "$TEMPDIR/$pkginfo" | _details

    while read -r pkgfile; do
        [ -n "$pkgfile" ] || continue

        # sha pkgfile
        IFS=' ' read -r _ pkgfile _ <<< "$pkgfile"

        info2 "#2 Fetch $pkgfile"

        _unzip "$pkgfile" || {
            error "<< Fetch package $pkgfile/$ARCH failed"
            return 1
        }
    done < "$TEMPDIR/$pkginfo"

    # no v1 package()
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

    info "## Install $NAME => $target"

    if ! mkdir -pv "$(dirname "$target")" | _details; then
        error "<< Permission Denied?"
        return 1
    fi

    for base in "${BASE[@]}"; do
        if _curl "$base" "$TEMPDIR/$NAME"; then
            cp -fv "$TEMPDIR/$NAME" "$target" 2>&1 | _details | xargs
            chmod -v a+x "$target" | _details

            # test target and exit
            "$target" help && exit 0
        fi
    done

    error "<< Update $(basename "$0") failed"
    return 127
}

# list installed cmdlets
list() {
    local width link real
    info "== List installed cmdlets"

    width="$(find . -type l -maxdepth 1 | wc -L)"

    while read -r link; do
        real="$(readlink "$link")"
        [[ "$real" =~ ^"$PREBUILTS" ]] || test -L "$real" || continue
        printf "%${width}s => %s\n" "$(basename "$link")" "$real"
    done < <(find . -type l -maxdepth 1)
}

# invoke cmd [args...]
invoke() {
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
        ls|list)
            list
            ;;
        search)
            search "${@:2}"
            ;;
        install)
            for x in "${@:2}"; do
                IFS=':' read -r bin alias <<< "$x"
                fetch "$bin" --install "$alias" || ret=$?
            done
            ;;
        rm|remove|uninstall)
            for x in "${@:2}"; do
                remove "$x" || ret=$?
            done
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
            find "$PREBUILTS/lib/pkgconfig" -name "*.pc" -exec \
                sed -i "s%^prefix=.*$%prefix=$PREBUILTS%g" {} \;
            ;;
        *)
            usage
            ;;
    esac
    exit $?
}

# shellcheck disable=SC2064
TEMPDIR="$(mktemp -d)" && trap "rm -rf $TEMPDIR" EXIT

# for quick install
if [ "$0" = "install" ]; then
    update
else
    cd "$(dirname "$0")" && invoke "$@" || exit $?
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
