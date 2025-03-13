#!/bin/bash 
#
# shellcheck disable=SC2155

set -eo pipefail
export LANG="${LANG:-en_US.UTF-8}"

ARCH="${CMDLETS_ARCH:-}"
VERSION=0.2

REPO=https://pub.mtdcy.top/cmdlets/latest
BASE=https://raw.githubusercontent.com/mtdcy/cmdlets/main/cmdlets.sh

usage() {
    cat << EOF
$(basename "$0") $VERSION
Copyright (c) 2025, mtdcy.chen@gmail.com

$(basename "$0") options [args ...]

Options:
    update                  - update $(basename "$0")
    fetch   <cmdlet>        - fetch cmdlet(s) from server
    install <cmdlet>        - fetch and install cmdlet(s)
    library <libname>       - fetch a library from server
    package <pkgname>       - fetch a package(cmdlets & libraries) from server
    help                    - show this help message

Examples:
    $(basename "$0") install minigzip                   # install the latest version
    $(basename "$0") install zlib/minigzip@1.3.1-2      # install the specific version

    $(basename "$0") package zlib                       # install the latest package
    $(basename "$0") package zlib@1.3.1-2               # install the specific version
EOF
}

error() { echo -ne "\\033[31m$*\\033[39m"; }
info()  { echo -ne "\\033[32m$*\\033[39m"; }
warn()  { echo -ne "\\033[33m$*\\033[39m"; }

if [ -z "$ARCH" ]; then
    case "$OSTYPE" in
        darwin*)
            ARCH="$(uname -m)-apple-darwin"
            ;;
        msys*)
            ARCH="$(uname -m)-msys-ucrt64"
            ;;
        linux*) # OSTYPE cann't be trusted
            if find /lib*/ld-musl-* &>/dev/null; then
                ARCH="$(uname -m)-linux-musl"
            else
                ARCH="$(uname -m)-linux-gnu"
            fi
            ;;
        *)
            ARCH="$(uname -m)-$OSTYPE"
            ;;
    esac
fi

PREFIX="$(dirname "$0")/prebuilts/$ARCH"
REPO="$REPO/$ARCH"

# get remote revision url
_revision() {
    # zlib/minigzip@1.3.1-2
    IFS='/@-' read -r a b c d <<< "$1"
    if [ -n "$b" ]; then
        [ "$c" = "latest" ] && echo "$REPO/$a/$b@latest" || echo "$REPO/$a/$b-$c-${d:-0}"
    else
        # latest version
        IFS='/' read -r a b <<< "$1"
        [ -n "$b" ] && echo "$REPO/$a/$b@latest" || echo "$REPO/$a@latest"
    fi
}

# get remote pkginfo url
_pkginfo() {
    # zlib@1.3.1-2
    IFS='@-' read -r a b c <<< "$1"
    if [ -n "$b" ] && [ "$b" != "latest" ]; then
        echo "$REPO/$a/pkginfo@$b-${c:-0}"
    else
        echo "$REPO/$a/pkginfo@latest"
    fi
}

# fetch cmdlet from server
cmdlet() {
    local revision="$(mktemp)"
    trap "rm -f $revision" EXIT

    # v2 cmdlet & applet 
    if curl --fail -sL -o "$revision" "$(_revision "$1")"; then
        info "Fetch $1 => $PREFIX\n"

        local sha pkgname
        IFS=' ' read -r sha pkgname _ <<< "$(tail -n1 "$revision")"

        mkdir -p "$PREFIX"
        curl --fail -# "$REPO/$pkgname" | tar -C "$PREFIX" -xz
    # v1 applet: deprecated
    elif curl --fail -sL -o "$revision" "$REPO/app/$1/$1-revision"; then
        info "Fetch applet $1 => $PREFIX\n"

        local sha pkgname
        IFS=' ' read -r sha pkgname _ <<< "$(tail -n1 "$revision")"

        mkdir -p "$PREFIX/app/$1"
        curl --fail -# "$REPO/app/$1/$pkgname" | tar -C "$PREFIX/app/$1" -xz
        chmod a+x "$PREFIX/app/$1/$1"
    # v1 cmdlet: deprecated
    elif curl --fail -sIL -o /dev/null "$REPO/bin/$1"; then
        info "Fetch cmdlet $1 => $PREFIX\n"

        mkdir -p "$PREFIX/bin"
        curl --fail -# -o "$PREFIX/bin/$1" "$REPO/bin/$1"
        chmod a+x "$PREFIX/bin/$1"
    else
        error "Fetch $1 failed\n"
        return 1
    fi
}

# fetch library from server
library() {
    local revision="$(mktemp)"
    trap "rm -f $revision" EXIT

    if curl --fail -s -o "$revision" "$(_revision "$1")"; then

        local sha libname
        IFS=' ' read -r sha libname _ <<< "$(tail -n1 "$revision")"

        mkdir -p "$PREFIX"
        curl --fail -# "$REPO/$libname" | tar -C "$PREFIX" -xz

        # update pkgconfig .pc
        find "$PREFIX/lib" -name "*.pc" -exec sed -e "s:^prefix=.*$:prefix=$PREFIX:p" -i {} \;
    else
        error "Fetch library $1 failed\n"
        return 1
    fi
}

# fetch package from server
package() {
    local pkginfo="$(mktemp)"
    trap "rm -f $pkginfo" EXIT

    if curl --fail -sL -o "$pkginfo" "$(_pkginfo "$1")"; then
        mkdir -p "$PREFIX"

        while read -r line; do
            [ -n "$line" ] || continue
            local sha filepath
            IFS=' ' read -r _ filepath _ <<< "$line"

            info "Fetch $(basename "$filepath") => $PREFIX\n"
            curl --fail -# "$REPO/$filepath" | tar -C "$PREFIX" -xz
        done < "$pkginfo"
    else
        error "Fetch package $1 failed\n"
        return 1
    fi
}

update() {
    if curl --fail -sIL -o /dev/null https://git.mtdcy.top/mtdcy/cmdlets/; then
        BASE=https://git.mtdcy.top/mtdcy/cmdlets/raw/branch/main/cmdlets.sh
    fi

    local dest 
    if [ -f "$0" ]; then
        dest="$0"
    elif [[ "$PATH" =~ $HOME/.bin ]]; then
        dest="$HOME/.bin/$(basename "$BASE")"
    else 
        dest="/usr/local/bin/$(basename "$BASE")"
    fi

    info "Install cmdlets => $dest\n"

    local tempfile="$(mktemp)"
    trap "rm -f $tempfile" EXIT

    curl --fail -# -o "$tempfile" "$BASE"

    chmod a+x "$tempfile"
    if [ -w "$(dirname "$dest")" ]; then
        mv -f "$tempfile" "$dest"
    else
        sudo mv -f "$tempfile" "$dest"
    fi
}

# never resolve symbolic here
name="$(basename "$0")"

if [ "$name" = "install" ] && [ $# -eq 0 ]; then
    update
elif [ "$name" = "fetch" ] && [ $# -eq 1 ]; then
    cmdlet "$1"
elif [ "$name" = "$(basename "$BASE")" ]; then
    case "$1" in
        update)
            update
            ;;
        install)    # fetch cmdlets
            for x in "${@:2}"; do
                cmdlet "$x"
                ln -sfv "$name" "$(dirname "$0")/$x"
            done
            ;;
        fetch)      # fetch bin file
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
    cmdlet="$PREFIX/app/$name/$name"
    [ -x "$cmdlet" ] || cmdlet="$PREFIX/bin/$name"
    [ -x "$cmdlet" ] || cmdlet "$name"

    # exec cmdlet
    cmdlet="$PREFIX/app/$name/$name"
    [ -x "$cmdlet" ] || cmdlet="$PREFIX/bin/$name"
    [ -x "$cmdlet" ] || error "no cmdlet $name found.\n"

    exec "$cmdlet" "$@"
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
