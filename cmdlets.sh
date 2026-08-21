#!/usr/bin/env bash
#
# shellcheck disable=SC2155

VERSION=1.1.0

# Changes:
#  1.1.0    - 20260821      - new stable release
#  1.0.8    - 20260820      - fix bugs
#  1.0.7    - 20260815      - new DOMAIN cmdlets.mtdcy.top
#  1.0.6    - 20260410      - code refactor
#  1.0.5    - 20260208      - fix update command
#                           - no sed in fetch()
#                           - fix `readlink: xxx: No such file or directory'
#  1.0.4    - 20260207      - add force update cmd in case manifest broken
#  1.0.3    - 20260202      - add caveats command
#  1.0.2    - 20260201      - fix pkgbuild, pkgvern may has '-'
#  1.0.1    - 20260130      - fix link command
#  1.0.0    - 20260129      - first release

set -eo pipefail

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL=en_US.UTF-8

# options
ARCH="${CMDLETS_ARCH:-}" # auto resolve arch later
REPO="${CMDLETS_REPO:-https://cmdlets.mtdcy.top/latest}"
PREBUILTS="${CMDLETS_PREBUILTS:-prebuilts}"

unset CMDLETS_ARCH CMDLETS_PREBUILTS CMDLETS_REPO

# constants
CLI="$0"
NAME="cmdlets.sh"
MANIFEST="$PREBUILTS/.manifest"
CMDLETS_LIST="$PREBUILTS/.cmdlets"
FILES_LIST="$PREBUILTS/.files"

# deferred command
DEFERRED=()

# detect architecture
if test -z "$ARCH"; then
    case "$(uname -s)" in
        Darwin)
            ARCH="$(uname -m)-apple-darwin"
            ;;
        Linux)
            ARCH="$(uname -m)-linux-gnu"
            ;;
        *)
            ARCH="$(uname -m)-w64-mingw32"
            ;;
    esac
fi

usage() {
    cat << EOF
$NAME $VERSION

Copyright (c) 2026, mtdcy.chen@gmail.com

Usage: $NAME cmd [args ...]

Options:
    update                      - update $NAME and cmdlets
    update  <cmdlet>            - update cmdlet

    list                        - list installed cmdlets
    list <cmdlets>              - list installed files of cmdlet(s)
    search  <name>              - search for cmdlet or resources
    install <cmdlet>            - fetch and install cmdlet
    remove  <cmdlet>            - remove cmdlet
    caveats <cmdlet>            - show cmdlet caveats

    version                     - show $NAME version

    help                        - show this help message

    (for developers)
    fetch   <cmdlet ...>        - fetch cmdlet(s)
    --update                    - update only cmdlets
    --update --force            - force update cmdlets

Examples:
    $NAME install minigzip                          # install the latest version
    $NAME install zlib/minigzip@1.3.1               # install the specific version

    # create resource link
    $NAME install mergetools                        # install git mergetools
    $NAME link    share/mergetools ~/.mergetools    # link mergetools to \$HOME
EOF
}

info()  { echo -e "\\033[32m$*\\033[39m" 1>&2; }
info1() { echo -e "\\033[35m$*\\033[39m" 1>&2; }
info2() { echo -e "\\033[34m$*\\033[39m" 1>&2; }
info3() { echo -e "\\033[36m$*\\033[39m" 1>&2; }

warn() {
    echo -e "** ⚠️ \\033[33m$*\\033[39m" 1>&2
}

die() {
    echo -e "** ❌ \\033[31m$*\\033[39m" 1>&2
    exit 1
}

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
# input: <target> <destination>
do_curl() (
    local dest="${2:-$TEMPDIR/$1}"

    mkdir -p "${dest%/*}"

    if [[ "$1" =~ ^https?:// ]]; then
        info "== 📥 $1"
        curl -fsL -o "$dest" "$1"
    elif [[ "$REPO" =~ ^flat+ ]]; then
        info "== 📥 $REPO/$ARCH/${1##*/}"
        curl -fsL -o "$dest" "${REPO#flat+}/$ARCH/${1##*/}"
    else
        info "== 📥 $REPO/$ARCH/$1"
        curl -fsL -o "$dest" "$REPO/$ARCH/$1"
    fi || return $?
    echo ">> ${dest##"$TEMPDIR/"}"
)

if tar --version | grep -qFw bsdtar; then
    # bsdtar will output lines 'x path/to/file'
    do_tar() {
        tar "$@" 2>&1 | sed 's/x //'
    }
else
    do_tar() {
        tar "$@"
    }
fi

if ln --version > /dev/null 2>&1; then
    # gnu ln
    do_ln() {
        ln -srf "$@"
    }
else
    # bsd realpath do not have --relative-to
    # input: <target> <relative to>
    relative_to() {
        local target="$(realpath "$1")"
        local to="$(realpath "$2")"
        local common="$target"
        local result=""

        # 循环找出最大公共祖先目录
        while [ "${to#$common/}" = "$to" ] && [ "$common" != "/" ]; do
            common=$(dirname "$common")
            result="../$result"
        done

        if [ "$common" = "/" ]; then
            # 如果退到了根目录才有交集
            result="$result${to#/}"
        else
            # 拼接剩余路径
            result="$result${to#$common/}"
        fi

        echo "$result"
    }

    # bsd ln
    do_ln() {
        if test -d "$2" || [[ "$2" =~ /$ ]]; then
            local relative="$(relative_to "$2" "$1")"
        else
            local relative="$(relative_to "$(dirname "$2")" "$1")"
        fi
        ln -sf "$relative" "$2"
    }
fi

# save package to PREBUILTS
do_unzip() (
    local zip="$1"
    if ! test -f "$zip"; then
        zip="$TEMPDIR/$1"
        do_curl "$1" "$zip" || return $?
    fi

    if test -n "$INSTALLED_FILES"; then
        do_tar -C "$PREBUILTS" -xvf "$zip" | tee -a "$INSTALLED_FILES" | _details
    else
        do_tar -C "$PREBUILTS" -xvf "$zip" | _details
    fi
)

# search manifest for package
#  input: name [--pkgname] [--pkgfile] [--any]
#  output: multi-line match results
_search() {
    # cmdlets:
    #   minigzip
    #   minigzip@1.3.1
    #   zlib/minigzip@1.3.1

    local pkgname pkgfile pkgvern

    IFS='@' read -r pkgfile pkgvern  <<< "${1%.tar.*}"

    # pkgname exists?
    [[ "$pkgfile" =~ / ]] && IFS='/' read -r pkgname pkgfile <<< "$pkgfile"

    options=("${@:2}")
    test -n "${options[*]}" || options=(--pkgfile --pkgname)

    for opt in "${options[@]}"; do
        case "$opt" in
            --pkgfile)
                if [ "$pkgvern" = "latest" ]; then
                    grep "^$pkgfile \|/$pkgfile@" "$MANIFEST" | tail -n1 || true
                elif test -n "$pkgvern"; then
                    grep "^$pkgfile@$pkgvern \|/$pkgfile@$pkgvern" "$MANIFEST" || true
                else
                    grep "^$pkgfile \|/$pkgfile@" "$MANIFEST" || true
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
do_search() {
    info3 "#3 🔍 Search $*"

    while IFS=' ' read -r _ pkgfile _; do
        printf '=> %s\n' "$pkgfile"
    done < <( _search "$@" | sort -u)
}

# edit file in place
if sed --version &> /dev/null; then
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

_caveats()  { echo "$PREBUILTS/caveats/${1//\//_}";     }

# fetch cmdlet: name [options]
#  input: name [--install [links...] ]
#  output: return 0 on success
#
#  name: [pkgname/]pkgfile[@pkgvern]
#   e.g:
#       bash
#       bash@3.2
#       bash32/bash@3.2
do_fetch() {
    local target="${1%.tar.*}" && shift 1

    local pkgname pkgfile pkgvern pkgbuild
    local caveats="$(_caveats "$target")"

    # handle options
    local install alias
    while [ $# -gt 0 ]; do
        case "$1" in
            --install)  install="yes" ;;
            --alias)    alias="$2" ;;
        esac
        shift
    done

    INSTALLED_FILES="$TEMPDIR/.files"
    true > "$INSTALLED_FILES"

    info "\n!! 🚀 Install cmdlet $target"

    # cmdlet v1: path/to/file
    _v1() {
        info1 "#1 📦 Fetch $1"
        # curl directly to symlink will override the real file.
        do_curl "bin/$1" || return $?
        mv -f "$TEMPDIR/bin/$1" "$PREBUILTS/bin/$1"
        chmod a+x "$PREBUILTS/bin/$1"
        echo "bin/$1" > "$INSTALLED_FILES"
    }

    # cmdlet v2: name
    _v2() {
        IFS='@' read -r pkgfile pkgvern <<< "${1%.tar.*}"
        test -n "$pkgvern" || pkgvern="latest"

        IFS='/' read -r pkgname pkgfile <<< "$pkgfile"
        test -n "$pkgfile" || pkgfile="$pkgname"

        local pkginfo="$pkgname/$pkgfile@$pkgvern"
        info2 "#2 📄 Fetch $1 ($pkginfo)"
        do_curl "$pkginfo" || return 1

        # v2: sha pkgfile
        IFS=' ' read -r _ pkgfile _ < <( tail -n1 "$TEMPDIR/$pkginfo")
        info2 "#2 📦 Fetch $1 ($pkgfile)"
        do_unzip "$pkgfile" || return 2   # updated files

        # v2: update pkgvern
        IFS='@' read -r _ pkgvern <<< "${pkgfile%.tar.*}"
    }

    # cmdlet v3/manifest: name pkgfile sha pkgbuild
    _v3() {
        # must update target name, e.g: bash@3.2 bash32/bash@3.2.57.tar.gz ...
        IFS=' ' read -r target pkgfile _ pkgbuild _ < <( _search "${1%.tar.*}" --pkgfile | tail -n 1)
        test -n "$pkgfile" || return 1

        info3 "#3 📦 Fetch $1 ($pkgfile)"
        do_unzip "$pkgfile" || return 2

        # have to update pkgname here
        IFS='/@' read -r pkgname pkgfile pkgvern <<< "${pkgfile%.tar.*}"

        # caveats: v3 only
        true > "$caveats"
        do_curl "$pkgname/$pkgname.caveats" "$caveats" 2> /dev/null || true
    }

    # install from local file.tar.gz
    _local() {
        # update target name and version
        IFS='@' read -r target pkgvern < <( basename "${1%.tar.*}")

        info "## 📦 Install $target ($1)"
        do_unzip "$1" || return 1
    }

    if test -f "$target" && [[ "$target" =~ \.tar\.gz$ ]]; then
        _local "$target" || die "Install from $target failed"
    elif _v3 "$target" || _v2 "$target" || _v1 "$target"; then
        true
    else
        die "Fetch $target/$ARCH failed"
    fi

    # update installed: name pkgvern pkgbuild
    _edit "\#^$target #d" "$CMDLETS_LIST"
    echo "$target ${pkgvern:-1.0} $pkgbuild" >> "$CMDLETS_LIST"

    # ln helper: width from to
    _ln_println() {
        if test -L "$3" && test -e "$3"; then
            printf "%${1}s -> %s (displace %s)\n" "$3" "$2" "$(readlink "$3")"
        else
            printf "%${1}s -> %s\n" "$3" "$2"
        fi
        do_ln "$2" "$3"
    }

    target="${target##*/}"                                      # remove pkgname
    test -f "$PREBUILTS/bin/$target" || target="${target%%@*}"  # remove pkgvern

    local links=()
    if test -n "$install"; then
        info "== ✨ Install target and link(s):"

        local width=$(grep "^bin/" "$INSTALLED_FILES" | _width)

        # install default links
        while read -r file; do
            file="$PREBUILTS/$file"
            if test -L "$file"; then
                _ln_println "$width" "$(readlink "$file")" "${file##*/}"
            else
                _ln_println "$width" "$file" "${file##*/}"
            fi
            links+=("${file##*/}")
        done < <( grep "^bin/" "$INSTALLED_FILES")

        # install user defined links
        if test -n "$alias"; then
            for link in ${alias//:/ }; do
                [ "$link" = "$target" ] && continue
                _ln_println "$width" "$target" "$link"
                links+=("$link")
            done
        fi
    fi

    # update files list: name files ...
    grep -Ev "^$target " "$FILES_LIST" > "$TEMPDIR/installed"
    {
        printf '%s ' "$target"
        while read -r file; do
            printf '%s ' "$PREBUILTS/$file"
        done < "$INSTALLED_FILES"

        # append symlinks
        for link in "${links[@]}"; do
            printf '%s ' "$link"
        done
        printf '\n'
    } >> "$TEMPDIR/installed"
    mv "$TEMPDIR/installed" "$FILES_LIST"

    # caveats
    if test -s "$caveats"; then
        info "== 📝 caveats:"
        cat "$caveats"
    fi

    unset INSTALLED_FILES
}

# create cmd alias or link prebuilts to other place
#  input: <targets ...> <destination>
do_link() {
    local targets=("${@:1:$(($# - 1))}")
    local to="${*:$#}"

    # alias     : link bash@3.2 bash                - create bash@3.2 alias in cmdlets.sh PWD
    # relative  : link bash@3.2 ./bash              - link bash@3.2 to current PWD
    # absolute  : link bash@3.2 /usr/local/bin/bash - link bash@3.2 to /usr/local/bin
    [[ "$to" =~ ^\./ ]] && to="$OLDPWD/$to" || true

    info "== 🔗 Link ${targets[*]} => $to"

    # prepare directories
    if [[ "$to" =~ /$ ]]; then
        mkdir -pv "$to"
    elif [[ "$to" =~ / ]]; then
        mkdir -pv "$(dirname "$to")"
    fi

    for target in "${targets[@]}"; do
        test -e "$target" || target="$PREBUILTS/$target"
        test -e "$target" || {
            warn "$target not exists"
            continue
        }

        if test -L "$target"; then
            echo "=> $to => $target ($(readlink "$target"))"
        else
            echo "=> $to => $target"
        fi
        do_ln "$target" "$to" | _details_escape
    done
}

# remove installed files of cmdlet
#  input: <cmdlet name>
do_remove() {
    local name="${1%.tar.*}" # formated name
    local caveats="$(_caveats "$name")"

    info "== 🗑️ Remove $name:"

    test -f "$CMDLETS_LIST" || return 0
    test -s "$caveats" && rm -rf "$caveats" || true

    _rm_println() {
        if test -L "$1"; then
            echo "=> removed '$1 -> $(readlink "$1")'"
            rm -rf "$1"
        else
            rm -rfv "$1" | _details
        fi
    }

    if grep -q "^$name " "$FILES_LIST"; then
        # fails with `rm: Argument list too long'
        #IFS=' ' read -r -a files < <( grep "^$name " "$FILES_LIST" | cut -d' ' -f2- )
        #_rm_println "${files[@]}"
        while read -r file; do
            _rm_println "$file"
        done < <( grep "^$name " "$FILES_LIST" | cut -d' ' -f2- | tr -s ' ' '\n')

        # clear recrods
        _edit "\#^$name #d" "$FILES_LIST"
        _edit "\#^$name #d" "$CMDLETS_LIST"
    else
        # remove links in PREBUILTS/bin
        while read -r link; do
            _rm_println "$link"
        done < <( find "$PREBUILTS/bin" -type l -lname "$name")

        # remove PREBUILTS/bin/target
        _rm_println "$PREBUILTS/bin/$name"

        # remove links in executable path
        while read -r link; do
            _rm_println "${link#./}"
        done < <( find . -maxdepth 1 -type l -lname "$name")

        # remove target
        _rm_println "$name"
    fi
}

do_update_int() {
    local pkgfile pkgvern pkgbuild options=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --force)    options+=(--force)   ;;
        esac
        shift 1
    done

    while IFS=' ' read -r pkgfile pkgvern pkgbuild; do
        info "!! 🚀 Try update $pkgfile ..."

        if test -z "$pkgbuild"; then
            info ">> no pkgbuild, always update"
            do_fetch "$pkgfile" --install
        else
            local _pkgfile _pkgver _pkgbuild

            # name pkgfile sha build
            IFS=' ' read -r _ _pkgfile _ _pkgbuild < <( _search "$pkgfile" --pkgfile | tail -n 1)

            if test -z "$_pkgfile"; then
                warn "no update found"
            elif [[ "${options[*]}" =~ --force ]]; then
                info ">> force update > $pkgvern $_pkgbuild"
                do_fetch "$pkgfile" --install
            elif [[ "$_pkgfile" != *"@$pkgvern.tar."* ]]; then
                info ">> new pkgvern > $_pkgfile"
                do_fetch "$pkgfile" --install
            elif [ "${_pkgbuild#*=}" -gt "${pkgbuild#*=}" ]; then
                info ">> new pkgbuild > $pkgvern $_pkgbuild"
                do_fetch "$pkgfile" --install
            fi
        fi
    done < <( sort "$CMDLETS_LIST")
}

do_fetch_manifest() {
    info "!! 📄 Fetch manifest"
    touch "$MANIFEST"
    do_curl cmdlets.manifest "$MANIFEST" || warn "Fetch manifest failed"
}

do_fetch_cli() {
    local target
    if [[ "$CLI" =~ "$NAME"$ ]]; then
        target="$CLI"
    elif [[ "$PATH" =~ $HOME/.bin ]]; then
        target="$HOME/.bin/$NAME"
    elif [[ "$PATH" =~ $HOME/.local/bin ]]; then
        target="$HOME/.local/bin/$NAME"
    else
        target="/usr/local/bin/$NAME"
    fi

    info "\n🚀 Install $NAME => $target"

    mkdir -pv "$(dirname "$target")" | _details

    test -w "$(dirname "$target")" || die "Permission Denied"

    if do_curl "$REPO/$NAME" "$target"; then
        chmod -v a+x "$target" | _details
        # update CLI
        CLI="$target"
    else
        die "do_curl $REPO/$NAME failed"
    fi
}

# prepare cmdlets.sh
do_bootstrap() {
    do_fetch_cli

    # always use new cli
    DEFERRED=("$CLI" install coreutils)
}

# update cmdlets.sh and then packages
do_update() {
    do_fetch_cli

    # always use new cli
    DEFERRED=("$CLI" --update) # => do_update_int
}

# list installed cmdlets
do_list() {
    test -f "$CMDLETS_LIST" || return 0

    while test -n "$1"; do
        case "$1" in
            --*) options+=("$1")   ;;
            *)   args+=("$1")   ;;
        esac
        shift 1
    done

    # defaults
    if test -z "${options[*]}"; then
        test -n "${args[*]}" && options=(--files)   || options=(--cmdlets)
    fi

    # println: width name info
    _ls_println() {
        printf "   %${1}s - %s\n" "$2" "${*:3}"
    }

    # println: files ...
    _ls_files_println() {
        while read -r file; do
            if test -L "$file"; then
                echo "=> $file -> $(readlink "$file")"
            else
                echo "=> $file"
            fi
        done < <(tr -s ' ' '\n')
    }

    for opt in "${options[@]}"; do
        case "$opt" in
            --cmdlets)
                info "== 📦 Installed cmdlets:"
                width="$(cut -d' ' -f1 < "$CMDLETS_LIST" | _width)"
                while IFS=' ' read -r name pkgvern pkgbuild; do
                    _ls_println "$width" "$name" "$pkgvern" "$pkgbuild"
                done < <( sort "$CMDLETS_LIST")
                ;;
            --links)
                info "== 📦 Installed links:"
                width="$(find . -maxdepth 1 -type l | _width)"

                while read -r link; do
                    real="$(readlink "$link")"
                    [[ "$real" =~ ^"$PREBUILTS" ]] || test -L "$real" || continue
                    _ls_println "$width" "${link##*/}" "$real"
                done < <( find . -maxdepth 1 -type l | sort -h)
                ;;
            --files)
                for x in "${args[@]}"; do
                    info "== 📦 Installed files of $x:"
                    grep "^$x " "$FILES_LIST" | cut -d' ' -f2- | _ls_files_println || {
                        # print link and target
                        echo "=> $x -> $(readlink "$x")"
                    }
                done
                ;;
        esac
    done
}

# do_process cmd [args...]
do_process() {
    local done=1 ret=0
    # early stage, no resources needed
    case "$1" in
        bootstrap)
            do_bootstrap
            ;;
        version)
            echo "$VERSION"
            ;;
        usage | help)
            usage
            ;;
        *)
            done=0
            ;;
    esac
    [ "$done" -ne 1 ] || exit "$ret"

    mkdir -pv "$PREBUILTS"/{bin,share,caveats}

    # Permission denied
    test -r "$PREBUILTS" || die "Read Permission Denied"

    # pre-install stage
    ret=0
    done=1
    case "$1" in
        ls | list)
            do_list "${@:2}"
            ;;
        ln | link)
            do_link "${@:2}"
            ;;
        rm | remove | uninstall)
            for x in "${@:2}"; do
                ( do_remove "$x" ) || ret=$?
            done
            ;;
        update) # update cmdlets cli and packages
            if test -z "$2"; then
                do_update
            fi
            ;;
        caveats | info)
            local caveats="$(_caveats "$2")"
            test -s "$caveats" && cat "$caveats" || info "<< no caveats found"
            ;;
        *)
            done=0
            ;;
    esac

    [ "$done" -ne 1 ] || exit "$ret"

    # Permission denied
    test -w "$PREBUILTS" || die "Write Permission Denied?"

    # always try to update manifest
    do_fetch_manifest

    # init directories and files
    touch "$CMDLETS_LIST"
    touch "$FILES_LIST"

    # install stage: everything should be ready now
    case "$1" in
        manifest)
            cat "$MANIFEST"
            ;;
        --update) # internel cmd
            do_update_int "${@:2}" || ret=$?
            ;;
        update) # update packages
            for x in "${@:2}"; do
                do_fetch "$x" --install || ret=$?
            done
            ;;
        search)
            do_search "${@:2}" || ret=$?
            ;;
        install) # fetch cmdlets and install symlinks
            for x in "${@:2}"; do
                IFS=':' read -r bin alias <<< "$x"
                ( do_fetch "$bin" --install --alias "$alias" ) || ret=$?
            done
            ;;
        fetch) # fetch cmdlets without install symlinks
            for x in "${@:2}"; do
                ( do_fetch "$x" ) || ret=$?
            done
            ;;
        *)
            usage
            ;;
    esac
    exit "$ret"
}

LOCKFILE="/tmp/cmdlets_${CLI//\//_}.lock"
test -f "$LOCKFILE" && die "cmdlets is locked."

true > "$LOCKFILE"

_on_exit() {
    rm -rf "$LOCKFILE"
    rm -rf "$TEMPDIR"

    if test -n "${DEFERRED[*]}"; then
        "${DEFERRED[@]}"
    fi
}
TEMPDIR="$(mktemp -d)" && trap _on_exit EXIT

# for quick install
if [ "$CLI" = "install" ]; then
    do_bootstrap
else
    cd "$(dirname "$0")" && do_process "$@" || exit $?
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
