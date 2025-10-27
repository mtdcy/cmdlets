#!/usr/bin/env bash
#
# shellcheck disable=SC2155

set -eo pipefail
export LANG="${LANG:-en_US.UTF-8}"

VERSION=1.0-alpha

ARCH="${CMDLETS_ARCH:-}" # auto resolve arch later
PREBUILTS="${CMDLETS_PREBUILTS:-prebuilts}"

# user defined repo
: "${REPO:=$CMDLETS_MAIN_REPO}"
# local private repo
: "${REPO:=http://pub.mtdcy.top/cmdlets/latest}"

# test repo connectivity
curl -fsIL --connect-timeout 1 -o /dev/null "$REPO" || unset REPO

# default public v3/git releases repo
: "${REPO:=flat+https://github.com/mtdcy/cmdlets/releases/download}"

unset CMDLETS_ARCH CMDLETS_PREBUILTS CMDLETS_MAIN_REPO

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
    elif [[ "$REPO" =~ ^flat+ ]]; then
        curl -fsIL -o /dev/null "${REPO#flat+}/$ARCH/${1##*/}"
    else
        curl -fsIL -o /dev/null "$REPO/$ARCH/$1"
    fi
)

# curl file to destination or TEMPDIR
_curl() (
    local dest="${2:-$TEMPDIR/$1}"

    mkdir -p "${dest%/*}"

    if [[ "$1" =~ ^https?:// ]]; then
        info "== curl < $1"
        curl -fsL -o "$dest" "$1"
    elif [[ "$REPO" =~ ^flat+ ]]; then
        info "== curl < $REPO/$ARCH/${1##*/}"
        curl -fsL -o "$dest" "${REPO#flat+}/$ARCH/${1##*/}"
    else
        info "== curl < $REPO/$ARCH/$1"
        curl -fsL -o "$dest" "$REPO/$ARCH/$1"
    fi || return $?
    echo ">> ${dest##"$TEMPDIR/"}"
)

if tar --version | grep -qFw bsdtar; then
    # bsdtar will output lines 'x path/to/file'
    _tar() {
        tar "$@" 2>&1 | sed 's/x //'
    }
else
    _tar() {
        tar "$@"
    }
fi

# save package to PREBUILTS
_unzip() (
    local zip="$1"
    if ! test -f "$zip"; then
        zip="$TEMPDIR/$1"
        _curl "$1" "$zip" || return $?
    fi

    _tar -C "$PREBUILTS" -xvf "$zip" | tee -a "$TEMPDIR/files" | _details
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

    IFS='@' read -r pkgfile pkgvern  <<< "${1%.tar.*}"

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
                : "${pkgname:=$pkgfile}"

                # needs pkgvern when search for pkgname?
                #if test -z "$pkgvern"; then
                #    IFS=' '  read -r _ pkgfile _ < <( grep " $pkgname/" "$MANIFEST" | tail -n 1 )
                #    IFS='/@' read -r _ _ pkgvern <<< "${pkgfile%.tar.*}"
                #fi
                grep " $pkgname/.*@$pkgvern" "$MANIFEST" || true
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

    while IFS=' ' read -r _ pkgfile _; do
        printf '=> %s\n' "$pkgfile"
    done < <( _search "$@" | sort -u )
}

# edit file in place
if sed --version &>/dev/null; then
_edit() {
    sed -i "$1" "$2"
}
else
_edit() {
    sed -i '' "$1" "$2"
}
fi

# replace 'wc -L' which is not availabe on macOS
_width() {
    awk '{ if ( length > x ) { x = length } } END { print x }'
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
    local target="$1"; shift 1
    local pkgname pkgfile pkgvern pkgbuild

    true > "$TEMPDIR/files"

    # cmdlet v1: path/to/file
    _v1() {
        info1 "#1 Fetch $1"
        # curl directly to symlink will override the real file.
        _curl "bin/$1" || return $?
        mv -f "$TEMPDIR/bin/$1" "$PREBUILTS/bin/$1"
        chmod a+x "$PREBUILTS/bin/$1"
        echo "bin/$1" > "$TEMPDIR/files"
    }

    # cmdlet v2: name
    _v2() {
        IFS='@' read -r pkgfile pkgvern <<< "${1%.tar.*}"
        test -n "$pkgvern" || pkgvern="latest"

        local pkginfo="$pkgfile@$pkgvern"
        info2 "#2 Fetch $1 < $pkginfo"
        _curl "$pkginfo" || return 1

        # v2: sha pkgfile
        IFS=' ' read -r _ pkgfile _ < <( tail -n1 "$TEMPDIR/$pkginfo" )
        info2 "#2 Fetch $1 < $pkgfile"
        _unzip "$pkgfile" || return 2   # updated files
    }

    # cmdlet v3/manifest: name pkgfile sha pkgbuild
    _v3() {
        IFS=' ' read -r _ pkgfile _ pkgbuild < <( _search "${1%.tar.*}" --pkgfile | tail -n 1 )
        test -n "$pkgfile" || return 1

        info3 "#3 Fetch $1 < $pkgfile"
        _unzip "$pkgfile" || return 2

        IFS='/@' read -r pkgname pkgfile pkgvern <<< "${pkgfile%.tar.*}"

        # caveats: v3 only
        true > "$TEMPDIR/caveats"
        _curl "$pkgname/$pkgname.caveats" "$TEMPDIR/caveats" 2>/dev/null || true
    }

    # install from local file.tar.gz
    _local() {
        # update target name and version
        IFS='@' read -r target pkgvern < <( basename "${1%.tar.*}" )

        info "## Fetch $target < $1"
        _unzip "$1" || return 1
    }

    if test -f "$target" && [[ "$target" =~ \.tar\.gz$ ]]; then
        _local "$target" || die "<< install from $target failed"
    elif _v3 "$target" || _v2 "$target" || _v1 "$target"; then
        true
    else
        die "<< Fetch $target/$ARCH failed"
    fi

    # update installed: name pkgvern pkgbuild
    _edit "\#^$target #d" "$PREBUILTS/.cmdlets"
    echo "$target ${pkgvern:-1.0} ${pkgbuild:-build=0}" >> "$PREBUILTS/.cmdlets"

    # update files list: name files ...
    _edit "\#^$target #d" "$PREBUILTS/.files"
    # fails with a lot of files
    #echo "$target $(sed "s%^%$PREBUILTS/%" "$TEMPDIR/files" | xargs)" >> "$PREBUILTS/.files"
    {
        echo -en "$target "
        sed "s%^%$PREBUILTS/%" "$TEMPDIR/files" | tr -s '\n' ' '
        echo -en "\n"
    } >> "$PREBUILTS/.files"

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

    target="${target##*/}"                                      # remove pkgname
    test -f "$PREBUILTS/bin/$target" || target="${target%%@*}"  # remove pkgvern

    local links=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --install)
                info "== Install target and link(s)"

                local width=$(grep "^bin/" "$TEMPDIR/files" | _width )

                # cmdlets.sh install bash@3.2:bash
                if test -n "$2" && [[ ! "$2" =~ ^-- ]]; then
                    _ln_println "$width" "$PREBUILTS/bin/$target" "$target"
                    for link in ${2//:/ }; do
                        [ "$link" = "$target" ] && continue
                        _ln_println "$width" "$target" "$link"
                        links+=( "$link" )
                    done
                    shift 1
                else
                    while read -r file; do
                        if test -L "$file"; then
                            _ln_println "$width" "$(readlink "$file")" "${file##*/}"
                        else
                            _ln_println "$width" "$file" "${file##*/}"
                        fi
                        links+=( "${file##*/}" )
                    done < <( grep "^bin/" "$TEMPDIR/files" | sed "s%^%$PREBUILTS/%" )
                fi
                ;;
            *)
                ;;
        esac
        shift 1
    done

    # append file symlinks to last line
    test -z "${links[*]}" || _edit "$ s%$% ${links[*]}%" "$PREBUILTS/.files"

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
    done < <( sort "$PREBUILTS/.cmdlets" )
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
    local name="${1%.tar.*}" # formated name
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
        _edit "\#^$name #d" "$PREBUILTS/.files"
        _edit "\#^$name #d" "$PREBUILTS/.cmdlets"
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

    # v2: latest version
    : "${pkgvern:=latest}"

    pkginfo="$pkgname/pkginfo@$pkgvern"

    true > "$TEMPDIR/pkginfo"

    # prefer v2 pkginfo than v3 manifest for developers
    if _curl "$pkginfo" "$TEMPDIR/pkginfo"; then
        # sha pkgfile ...
        IFS=' ' read -r -a pkgfiles < <( cut -d' ' -f2 < "$TEMPDIR/pkginfo" | xargs )
    else
        # v3/manifest: name pkgfile sha ...
        if test -z "$pkgvern" || [ "$pkgvern" = "latest" ]; then
            IFS=' '  read -r _ pkginfo _ < <( _search "$1" --pkgname | tail -n 1 )
            IFS='/@' read -r _ _ pkgvern <<< "${pkginfo%.tar.*}"
        fi
        test -n "$pkgvern"                          || die "<< failed to find pkgvern for $pkgname"

        IFS=' ' read -r -a pkgfiles < <( _search "$pkgname@$pkgvern" --pkgname | cut -d' ' -f2 | xargs )
    fi

    test -n "${pkgfiles[*]}"                        || die "<< Fetch package $1/$ARCH failed"

    info "=> ${pkgfiles[*]}"

    for pkgfile in "${pkgfiles[@]}"; do
        info "## Fetch $pkgfile"
        _unzip "$pkgfile"                           || die "<< Fetch package $pkgfile/$ARCH failed"
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

            # caveats about coretuils
            info "\n\t🌹🌹🌹 $NAME requires coreutils to work properly 🌹🌹🌹\n"

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
                width="$(cut -d' ' -f1 < "$PREBUILTS/.cmdlets" | _width)"
                while IFS=' ' read -r name info; do
                    _ls_println "$width" "$name" "$info"
                done < <( sort "$PREBUILTS/.cmdlets" )
                ;;
            --files)
                for x in "${args[@]}"; do
                    info "== List installed files of $x"
                    grep "^$x " "$PREBUILTS/.files" | cut -d' ' -f2- | tr -s ' ' '\n' | _details || {
                        # print link and target
                        echo "=> $x -> $(readlink "$x")"
                    }
                done
                ;;
            --links)
                info "== List installed links"
                width="$(find . -maxdepth 1 -type l | _width)"

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
    case "$1" in
        usage|help|ls|list|ln|link|rm|remove|uninstall) ;;
        *)
            _curl "${MANIFEST##*/}" "$MANIFEST" || warn "== Fetch manifest failed"
            ;;
    esac

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
            # no fix pc here, otherwise rsync will upload these files again
            #while read -r pc; do
            #    _edit "s%^prefix=.*$%prefix=$PREBUILTS%g" "$pc"
            #done < <( find "$PREBUILTS/lib/pkgconfig" -name "*.pc" )
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
