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

LOCAL_REPO=http://pub.mtdcy.top/cmdlets/latest

# test private repo first
if test -z "${CMDLETS_MAIN_REPO:-}" && curl -fsIL --connect-timeout 1 -o /dev/null "$LOCAL_REPO"; then
    REPO="$LOCAL_REPO"
else
    # v3/git public repo
    REPO="${CMDLETS_MAIN_REPO:-https://github.com/mtdcy/cmdlets/releases/download}"
fi

INSTALLERS=(
    "https://git.mtdcy.top/mtdcy/cmdlets/raw/branch/main/cmdlets.sh"
    "https://raw.githubusercontent.com/mtdcy/cmdlets/main/cmdlets.sh"
)

NAME="$(basename "${INSTALLERS[0]}")"

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
    update                      - update $NAME and cmdlets
    update  <cmdlet>            - update cmdlet

    list                        - list installed cmdlets
    search  <name>              - search for cmdlet, library or package
    install <cmdlet>            - fetch and install cmdlet
    remove  <cmdlet>            - remove cmdlet

    help                        - show this help message

    (for developers)
    fetch   <cmdlet ...>        - fetch cmdlet(s)
    package <pkgname ...>       - fetch package(s) (cmdlets & libraries)

Examples:
    $NAME install minigzip                          # install the latest version
    $NAME install zlib/minigzip@1.3.1               # install the specific version

    $NAME package zlib                              # install the latest package
    $NAME package zlib@1.3.1                        # install the specific version

    # create resource link
    $NAME install mergetools                        # install git mergetools
    $NAME link    share/mergetools ~/.mergetools    # link mergetools to \$HOME
EOF
}

info()  { echo -e "\\033[32m$*\\033[39m" 1>&2; }
warn()  { echo -e "\\033[33m$*\\033[39m" 1>&2; }
info1() { echo -e "\\033[35m$*\\033[39m" 1>&2; }
info2() { echo -e "\\033[34m$*\\033[39m" 1>&2; }
info3() { echo -e "\\033[36m$*\\033[39m" 1>&2; }

die() { echo -e "\\033[31m$*\\033[39m" 1>&2; exit 1; }

# prepend each line with '=> '
_details() {
    sed 's/^/=> /'
}

_details_escape() {
    sed 's/^/=> /' | xargs
}

# is file existing in repo
_exists() (
    if [[ "$1" =~ ^https?:// ]]; then
        curl -fsIL -o /dev/null "$1"
    else
        curl -fsIL -o /dev/null "$REPO/$ARCH/$1"
    fi
)

# curl file to destination or TEMPDIR
_curl() (
    local source
    local dest="${2:-$TEMPDIR/$1}"

    mkdir -p "${dest%/*}"

    [[ "$1" =~ ^https?:// ]] && source="$1" || source="$REPO/$ARCH/$1"

    info "== curl < $source"
    curl -fsSL "$source" -o "$dest" || return $?
    echo ">> ${dest##"$TEMPDIR/"}"
)

# save package to PREBUILTS
_unzip() (
    local zip="$1"
    if ! test -f "$zip"; then
        zip="$TEMPDIR/$1"
        _curl "$1" "$zip" || return $?
    fi

    tar -C "$PREBUILTS" -xvf "$zip" | tee -a "$TEMPDIR/files" | _details
)

# cmdlet v1
#  input: path/to/file
_v1() {
    local name="$1"

    [[ "$name" =~ / ]] || name="bin/$name"

    info1 "#1 Fetch $name"

    _curl "$name" || return $?

    mkdir -p "$PREBUILTS/$(dirname "$name")"

    cp -f "$TEMPDIR/$name" "$PREBUILTS/$name"

    chmod a+x "$PREBUILTS/$name"

    echo "$name" > "$TEMPDIR/files"

    # update installed: name version build=n
    sed -i "\#^$1 #d" "$PREBUILTS/.cmdlets"
    echo "$1 0.0 build=0" >> "$PREBUILTS/.cmdlets"
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

    # update installed: name version build=n
    sed -i "\#^$1 #d" "$PREBUILTS/.cmdlets"
    echo "$1 $pkgver build=0" >> "$PREBUILTS/.cmdlets"
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
#  input: pkgfile [options]
#  output: return 0 on success
_v3() {
    [ "$API" = "v3" ] || return 127

    local pkgname pkgfile pkgver

    IFS=' ' read -r _ pkgfile _ pkgbuild < <( _search "$1" "${@:2}" | tail -n 1 )

    test -n "$pkgfile" || return 1

    info3 "#3 Fetch $1 < $pkgfile"

    # v3 git releases do not have file hierarchy
    _unzip "$pkgfile" || _unzip "${pkgfile##*/}" || return 1

    IFS='/@' read -r pkgname pkgfile pkgver <<< "${pkgfile%.tar.*}"

    # caveats
    _curl "$pkgname/$pkgname.caveats" "$TEMPDIR/caveats" || true > "$TEMPDIR/caveats"

    # update installed: name version build=n
    sed -i "\#^$1 #d" "$PREBUILTS/.cmdlets"
    echo "$1 $pkgver $pkgbuild" >> "$PREBUILTS/.cmdlets"
}

# v3 only
search() {
    info3 "#3 Search $*"

    _search "$@" | sort -u | _details
}

# fetch cmdlet: name [options]
#  input: name [--install [links...] ]
#  output: return 0 on success
fetch() {
    true > "$TEMPDIR/files"

    if test -f "$1" && [[ "$*" == *" --local"* ]]; then
        info "## Fetch < $1"
        _unzip "$1"
    elif _v3 "$1" --pkgfile || _v2 "$1" || _v1 "$1"; then
        true
    else
        die "<< Fetch $1/$ARCH failed"
    fi

    # update files list: name files ...
    sed -i "\#^$1 #d" "$PREBUILTS/.files"
    echo "$1 $(sed "s%^%$PREBUILTS/%" "$TEMPDIR/files" | xargs)" >> "$PREBUILTS/.files"

    # target with or without version
    target="${1##*/}"
    test -f "$PREBUILTS/bin/$target" || target="${target%%@*}"

    # ln helper
    _ln_println() {
        printf "%${1}s -> %s\n" "$3" "$2"
        ln -sf "$2" "$3"
    }

    shift 1
    local installed=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --install)
                info "== Install target and link(s)"

                local width=$(grep "^bin/" "$TEMPDIR/files" | wc -L)

                while read -r file; do
                    _ln_println "$width" "$file" "${file##*/}"
                    installed+=( "${file##*/}" )
                done < <( grep "^bin/" "$TEMPDIR/files" | sed "s%^%$PREBUILTS/%" )

                # cmdlets.sh install bash@3.2:bash
                if test -n "$2" && [[ ! "$2" =~ ^-- ]]; then
                    # shellcheck disable=SC2206
                    local links=( ${2//:/ } )

                    for link in "${links[@]//*\//}"; do
                        [ "$link" = "$target" ] && continue
                        _ln_println "$width" "$target" "$link"
                        installed+=( "$link" )
                    done
                    shift 1
                fi
                ;;
            *)
                ;;
        esac
        shift 1
    done

    if test -n "${installed[*]}"; then
        # append installed symlinks to last line
        sed -i "$ s%$% ${installed[*]}%" "$PREBUILTS/.files"
    fi

    # caveats
    if test -s "$TEMPDIR/caveats"; then
        info "== Caveats:"
        cat "$TEMPDIR/caveats"
    fi
}

update() {
    local pkgfile pkgver pkgbuild
    while IFS=' ' read -r pkgfile pkgver pkgbuild; do
        info "\n🚀 Update $pkgfile ..."

        if test -z "$pkgbuild"; then
            info ">> no pkgbuild, always update"
            fetch "$pkgfile" --install
        else
            local _pkgfile _pkgver _pkgbuild

            # name pkgfile sha build
            IFS=' ' read -r _ _pkgfile _ _pkgbuild < <( _search "$pkgfile" --pkgfile | tail -n 1 )

            if test -z "$_pkgfile"; then
                warn "<< update not found"
            elif [[ "$_pkgfile" != *"@$pkgver.tar."* ]]; then
                info ">> pkgvern updated"
                fetch "$pkgfile" --install
            elif [ "${_pkgbuild#*=}" -gt "${pkgbuild#*=}" ]; then
                info ">> pkgbuild updated"
                fetch "$pkgfile" --install
            else
                info "<< no update"
            fi
        fi
    done < "$PREBUILTS/.cmdlets"
}


# link prebuilts to other place
#  input: <targets ...> <destination>
link() {
    local targets=( "${@:1:$(($#-1))}" )
    local to="${@:$#}"

    [[ "$to" =~ ^/ ]] || to="$OLDPWD/$to"

    info "== Link ${targets[*]} => $to"

    if [ ${#targets[@]} -gt 1 ]; then
        mkdir -pv "$to" | _details
    else
        mkdir -pv "${to%/*}" | _details
    fi

    for x in "${targets[@]}"; do
        test -e "$x" || x="$PREBUILTS/$x"

        test -e "$x" || die "<< $x not exists"

        # relative path: avoid using ln -srfv
        x="$(realpath "$x" --relative-to="${to%/*}")"
        ln -sfv "$x" "$to" | _details_escape
    done
}

# remove cmdlets
#  input: name
remove() {
    info "== remove $1"

    _rm_println() {
        rm -rfv "$@" | _details
    }

    if grep -q "^$1 " "$PREBUILTS/.files"; then
        IFS=' ' read -r -a files < <( grep "^$1 " "$PREBUILTS/.files" | cut -d' ' -f2- )

        _rm_println "${files[@]}"

        # clear recrods
        sed -i "\#^$1 #d" "$PREBUILTS/.files"
        sed -i "\#^$1 #d" "$PREBUILTS/.cmdlets"
    else
        # remove links in PREBUILTS/bin
        while read -r link; do
            _rm_println "$link"
        done < <( find "$PREBUILTS/bin" -type l -lname "$1" )

        # remove PREBUILTS/bin/target
        _rm_println "$PREBUILTS/bin/$1"

        # remove links in executable path
        while read -r link; do
            _rm_println "$link"
        done < <( find . -maxdepth 1 -type l -lname "$1" )

        # remove target
        _rm_println "$1"
    fi
}

# fetch package
package() {
    local pkgname pkgver pkgfile pkginfo

    # zlib@1.3.1
    IFS='@' read -r pkgname pkgver <<< "$1"

    # cmdlet v3/manifest
    if [ "$API" = "v3" ]; then
        IFS=' ' read -r -a pkgfile < <( _search "$1" --pkgname | awk '{print $1}' | sort -u | xargs )

        test -n "${pkgfile[*]}" || die "<< Fetch package $1/$ARCH failed"

        info3 "#3 Fetch package $1 < ${pkgfile[*]}"

        for file in "${pkgfile[@]}"; do
            _v3 "$pkgname/$file" --pkgfile || die "<< Fetch package $file/$ARCH failed"
        done

        touch "$PREBUILTS/.$pkgname.d" # mark as ready
        return 0
    fi

    info2 "#2 Fetch package $1"

    [ -n "$pkgver" ] || pkgver=latest

    pkginfo="$pkgname/pkginfo@$pkgver"

    _curl "$pkginfo" || die "<< Fetch $pkginfo failed"

    cat "$TEMPDIR/$pkginfo" | _details

    while read -r pkgfile; do
        [ -n "$pkgfile" ] || continue

        # sha pkgfile
        IFS=' ' read -r _ pkgfile _ <<< "$pkgfile"

        info2 "#2 Fetch $pkgfile"

        _unzip "$pkgfile" || die "<< Fetch package $pkgfile/$ARCH failed"
    done < "$TEMPDIR/$pkginfo"

    # no v1 package()
}

install() {
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

    mkdir -pv "$(dirname "$target")" | _details || die "<< Permission Denied?"

    for inst in "${INSTALLERS[@]}"; do
        if _curl "$inst" "$TEMPDIR/$NAME"; then
            cp -fv "$TEMPDIR/$NAME" "$target" 2>&1 | _details_escape
            chmod -v a+x "$target" | _details

            # test target and exit
            _on_exit && exec "$target" --update
        fi
    done

    die "<< Update $(basename "$0") failed"
}

# list installed cmdlets
list() {
    _ls_println() {
        printf "   %${1}s - %s\n" "$2" "${*:3}"
    }

    if test -n "$*"; then
        ### for developers ###
        while [ $# -gt 0 ]; do
            case "$1" in
                --cmdlets)
                    info "== List installed cmdlets"
                    width="$(cut -d' ' -f1 < "$PREBUILTS/.cmdlets" | wc -L)"
                    while IFS=' ' read -r name info; do
                        _ls_println "$width" "$name" "$info"
                    done < "$PREBUILTS/.cmdlets"
                    ;;
                --installed)
                    if test -n "$2" && [[ ! "$2" =~ ^-- ]]; then
                        info "== List installed files of $2"
                        for x in $(grep "^$2 " "$PREBUILTS/.files" | tail -n1 | cut -d' ' -f2-); do
                            printf "=> %s\n" "$x"
                        done
                        shift
                    else
                        info "== List all installed files"
                        while IFS=' ' read -r _ files; do
                            for x in $files; do
                                printf "=> %s\n" "$x"
                            done
                        done < "$PREBUILTS/.files"
                    fi
                    ;;
            esac
            shift 1
        done
    else
        info "== List installed cmdlets"
        width="$(find . -maxdepth 1 -type l | wc -L)"

        while read -r link; do
            real="$(readlink "$link")"
            [[ "$real" =~ ^"$PREBUILTS" ]] || test -L "$real" || continue
            _ls_println "$width" "${link##*/}" "$real"
        done < <( find . -maxdepth 1 -type l | sort -h )
    fi
}

# invoke cmd [args...]
invoke() {
    # init directories and files
    mkdir -pv "$PREBUILTS"
    touch "$PREBUILTS/.cmdlets"
    touch "$PREBUILTS/.files"

    export MANIFEST="$PREBUILTS/cmdlets.manifest"

    touch "$MANIFEST"
    _curl "${MANIFEST##*/}" "$MANIFEST" || warn "== Fetch manifest failed"

    # handle commands
    local ret=0
    case "$1" in
        manifest)
            cat "$MANIFEST"
            ;;
        --update) # internel cmd
            update
            ;;
        update)
            if test -n "$2"; then
                fetch "$2" || ret=$?
            else
                install
            fi
            ;;
        ls|list)
            list "${@:2}"
            ;;
        ln|link)
            link "${@:2}"
            ;;
        search)
            search "${@:2}"
            ;;
        install)
            if [[ "${*:2}" == *" --"* ]]; then
                fetch "${@:2}"
                exit $?
            fi
            for x in "${@:2}"; do
                IFS=':' read -r bin alias <<< "$x"
                ( fetch "$bin" --install "$alias" ) || ret=$?
            done
            ;;
        rm|remove|uninstall)
            for x in "${@:2}"; do
                ( remove "$x" ) || ret=$?
            done
            ;;
        fetch)      # fetch cmdlets
            for x in "${@:2}"; do
                ( fetch "$x" ) || ret=$?
            done
            ;;
        package)    # fetch package files
            for x in "${@:2}"; do
                ( package "$x" ) || true # ignore errors
            done
            find "$PREBUILTS/lib/pkgconfig" -name "*.pc" -exec \
                sed -i "s%^prefix=.*$%prefix=$PREBUILTS%g" {} \;
            ;;
        *)
            usage
            ;;
    esac
    exit "$ret"
}

LOCKFILE="/tmp/${0//\//_}.lock"
test -f "$LOCKFILE" && die "cmdlets is locked."

true > "$LOCKFILE"

_on_exit() {
    rm -rf "$LOCKFILE"
    rm -rf "$TEMPDIR"
}
TEMPDIR="$(mktemp -d)" && trap _on_exit EXIT

# for quick install
if [ "$0" = "install" ]; then
    install
else
    cd "$(dirname "$0")" && invoke "$@" || exit $?
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
