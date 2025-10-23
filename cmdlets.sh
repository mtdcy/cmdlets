#!/usr/bin/env bash
#
# shellcheck disable=SC2155

set -eo pipefail
export LANG="${LANG:-en_US.UTF-8}"

VERSION=1.0-alpha

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

# search manifest for package
#  input: name [--pkgname] [--pkgfile] [--any]
#  output: multi-line match results
_search() {
    # cmdlets:
    #   minigzip
    #   minigzip@1.3.1
    #   zlib/minigzip@1.3.1
    # packages:
    #   zlib
    #   zlib@1.3.1

    local pkgname pkgfile pkgvern

    IFS='@' read -r pkgfile pkgvern  <<< "$1"

    # v3: no latest support
    [ "$pkgvern" = "latest" ] && unset pkgvern || true

    # pkgname exists?
    [[ "$pkgfile" =~ / ]] && IFS='/' read -r pkgname pkgfile <<< "$pkgfile"

    options=( "${@:2}" )
    test -n "${options[*]}" || options=( --pkgfile --pkgname )

    for opt in "${options[@]}"; do
        case "$opt" in
            --pkgfile)
                if test -n "$pkgvern"; then
                    grep "^$pkgfile@$pkgvern \|/$pkgfile@$pkgvern" "$MANIFEST" || true
                else
                    grep "^$pkgfile " "$MANIFEST" || true
                fi
                ;;
            --pkgname)
                grep " ${pkgname:-$pkgfile}/.*@$pkgvern" "$MANIFEST" || true
                ;;
            --any)
                grep -F "$1" "$MANIFEST" || true
                ;;
        esac
    done | uniq
}

# v3 only
search() {
    info3 "#3 Search $*"

    _search "$@" | sort -u | _details
}

# fetch cmdlet: name [options]
#  input: name [--install [links...] ]
#  output: return 0 on success
#
#  name: [pkgname/]pkgfile[@pkgvern]
#   e.g:
#       bash
#       bash@3.2
#       bash32/bash@3.2
fetch() {
    true > "$TEMPDIR/files"

    # clear installed: name version build=n
    sed -i "\#^${1##*/} #d" "$PREBUILTS/.cmdlets"

    mkdir -p "$PREBUILTS/bin"
    # cmdlet v1: path/to/file
    _v1() {
        info1 "#1 Fetch $1"
        local name="bin/$1"
        _curl "$name" "$PREBUILTS/$name" && chmod a+x "$PREBUILTS/$name" || return $?

        echo "$name" > "$TEMPDIR/files"
        echo "$1 1.0 build=0" >> "$PREBUILTS/.cmdlets"
    }

    # cmdlet v2: name
    _v2() {
        local pkgfile pkgvern pkginfo

        IFS='@' read -r pkgfile pkgvern <<< "$1"
        test -n "$pkgvern" || pkgvern="latest"
        pkginfo="$pkgfile@$pkgvern"

        info2 "#2 Fetch $1 < $pkginfo"
        _curl "$pkginfo" || return 1

        # v2: sha pkgfile
        IFS=' ' read -r _ pkgfile _ < <(tail -n1 "$TEMPDIR/$pkginfo")

        info2 "#2 Fetch $1 < $pkgfile"
        _unzip "$pkgfile" || return 2   # updated files

        echo "${1##*/} $pkgvern build=0" >> "$PREBUILTS/.cmdlets"
    }

    # cmdlet v3/manifest: pkgfile
    _v3() {
        local pkgname pkgfile pkgvern

        IFS=' ' read -r _ pkgfile _ pkgbuild < <( _search "$1" "${@:2}" | tail -n 1 )
        test -n "$pkgfile" || return 1

        info3 "#3 Fetch $1 < $pkgfile"
        # v3 git releases do not have file hierarchy
        _unzip "$pkgfile" || _unzip "${pkgfile##*/}" || return 1

        IFS='/@' read -r pkgname pkgfile pkgvern <<< "${pkgfile%.tar.*}"

        # caveats
        _curl "$pkgname/$pkgname.caveats" "$TEMPDIR/caveats" 2>/dev/null || true > "$TEMPDIR/caveats"

        # update installed
        echo "${1##*/} $pkgvern $pkgbuild" >> "$PREBUILTS/.cmdlets"
    }

    if test -f "$1" && [[ "$*" == *" --local"* ]]; then
        info "## Fetch < $1"
        _unzip "$1"
    elif _v3 "$1" --pkgfile || _v2 "$1" || _v1 "$1"; then
        true
    else
        die "<< Fetch $1/$ARCH failed"
    fi

    # target: remove pkgname
    target="${1##*/}"

    # update files list: name files ...
    sed -i "\#^$target #d" "$PREBUILTS/.files"
    # fails with a lot of files
    #echo "$1 $(sed "s%^%$PREBUILTS/%" "$TEMPDIR/files" | xargs)" >> "$PREBUILTS/.files"
    {
        echo -en "$target "
        sed "s%^%$PREBUILTS/%" "$TEMPDIR/files" | tr -s '\n' ' '
        echo -en "\n"
    } >> "$PREBUILTS/.files"

    # target with or without version
    test -f "$PREBUILTS/bin/$target" || target="${target%%@*}"

    # ln helper: width from to
    _ln_println() {
        local exist="$(readlink "$3")"
        if test -n "$exist" && [ "$exist" != "$2" ]; then
            printf "%${1}s -> %s (displace %s)\n" "$3" "$2" "$exist"
        else
            printf "%${1}s -> %s\n" "$3" "$2"
        fi
        ln -sf "$2" "$3"
    }

    shift 1
    local links=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --install)
                info "== Install target and link(s)"

                local width=$(grep "^bin/" "$TEMPDIR/files" | wc -L)

                while read -r file; do
                    _ln_println "$width" "$file" "${file##*/}"
                    links+=( "${file##*/}" )
                done < <( grep "^bin/" "$TEMPDIR/files" | sed "s%^%$PREBUILTS/%" )

                # cmdlets.sh install bash@3.2:bash
                if test -n "$2" && [[ ! "$2" =~ ^-- ]]; then
                    for link in ${2//:/ }; do
                        [ "$link" = "$target" ] && continue
                        _ln_println "$width" "$target" "$link"
                        links+=( "$link" )
                    done
                    shift 1
                fi
                ;;
            *)
                ;;
        esac
        shift 1
    done

    # append file symlinks to last line
    test -z "${links[*]}" || sed -i "$ s%$% ${links[*]}%" "$PREBUILTS/.files"

    # caveats
    if test -s "$TEMPDIR/caveats"; then
        info "== Caveats:"
        cat "$TEMPDIR/caveats"
    fi
}

update() {
    local pkgfile pkgvern pkgbuild
    while IFS=' ' read -r pkgfile pkgvern pkgbuild; do
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
            elif [[ "$_pkgfile" != *"@$pkgvern.tar."* ]]; then
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
    local name="${1##*/}" # formated name
    info "== remove $name"

    _rm_println() {
        if test -L "$1"; then
            echo "=> removed '$1 -> $(readlink "$1")'"
            rm -rf "$1"
        else
            rm -rfv "$1" | _details
        fi
    }

    if grep -q "^$name " "$PREBUILTS/.files"; then
        # fails with `rm: Argument list too long'
        #IFS=' ' read -r -a files < <( grep "^$name " "$PREBUILTS/.files" | cut -d' ' -f2- )
        #_rm_println "${files[@]}"
        while read -r file; do
            _rm_println "$file"
        done < <( grep "^$name " "$PREBUILTS/.files" | cut -d' ' -f2- | tr -s ' ' '\n' )

        # clear recrods
        sed -i "\#^$name #d" "$PREBUILTS/.files"
        sed -i "\#^$name #d" "$PREBUILTS/.cmdlets"
    else
        # remove links in PREBUILTS/bin
        while read -r link; do
            _rm_println "$link"
        done < <( find "$PREBUILTS/bin" -type l -lname "$name" )

        # remove PREBUILTS/bin/target
        _rm_println "$PREBUILTS/bin/$name"

        # remove links in executable path
        while read -r link; do
            _rm_println "${link#./}"
        done < <( find . -maxdepth 1 -type l -lname "$name" )

        # remove target
        _rm_println "$name"
    fi
}

# fetch package
package() {
    local pkgname pkgvern pkginfo pkgfiles

    # priority: v2 > v3, no v1 package()

    info "📦 Fetch package $1:"

    # zlib@1.3.1
    IFS='@' read -r pkgname pkgvern <<< "$1"

    # v3: latest tag
    test -n "$pkgvern" || pkgvern=latest

    pkginfo="$pkgname/pkginfo@$pkgvern"

    true > "$TEMPDIR/pkginfo"

    # prefer v2 pkginfo than v3 manifest for developers
    if _curl "$pkginfo" "$TEMPDIR/pkginfo"; then
        # sha pkgfile ...
        IFS=' ' read -r -a pkgfiles < <( cut -d' ' -f2 < "$TEMPDIR/pkginfo" | xargs )
    else
        # name pkgfile sha ...
        IFS=' ' read -r -a pkgfiles < <( _search "$1" --pkgname | cut -d' ' -f2 | xargs )
    fi

    test -n "${pkgfiles[*]}"            || die "<< Fetch package $1/$ARCH failed"

    info "=> ${pkgfiles[*]}"

    for pkgfile in "${pkgfiles[@]}"; do
        info "## Fetch $pkgfile"
        _unzip "$pkgfile"               || die "<< Fetch package $pkgfile/$ARCH failed"
    done

    touch "$PREBUILTS/.$pkgname.d" # mark as ready

    echo ""
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
    while test -n "$1"; do
        case "$1" in
            --*) options+=( "$1" ) ;;
            *)   args+=( "$1" ) ;;
        esac
        shift 1
    done

    # defaults
    if test -z "${options[*]}"; then
        test -n "${args[*]}" && options=( --files ) || options=( --cmdlets )
    fi

    _ls_println() {
        printf "   %${1}s - %s\n" "$2" "${*:3}"
    }

    for opt in "${options[@]}"; do
        case "$opt" in
            --cmdlets)
                info "== List installed cmdlets"
                width="$(cut -d' ' -f1 < "$PREBUILTS/.cmdlets" | wc -L)"
                while IFS=' ' read -r name info; do
                    _ls_println "$width" "$name" "$info"
                done < "$PREBUILTS/.cmdlets"
                ;;
            --files)
                for x in "${args[@]}"; do
                    info "== List installed files of $x"
                    grep "^$x " "$PREBUILTS/.files" | cut -d' ' -f2- | tr -s ' ' '\n' | _details
                done
                ;;
            --links)
                info "== List installed links"
                width="$(find . -maxdepth 1 -type l | wc -L)"

                while read -r link; do
                    real="$(readlink "$link")"
                    [[ "$real" =~ ^"$PREBUILTS" ]] || test -L "$real" || continue
                    _ls_println "$width" "${link##*/}" "$real"
                done < <( find . -maxdepth 1 -type l | sort -h )
                ;;
        esac
    done
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
