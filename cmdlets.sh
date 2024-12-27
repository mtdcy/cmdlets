#!/bin/bash

set -eo pipefail

export LANG="${LANG:-en_US.UTF-8}"

# never resolve symbolic here
ROOT="$(cd "$(dirname "$0")"; pwd)/prebuilts"

REPO=https://pub.mtdcy.top/cmdlets/latest
BASE=https://raw.githubusercontent.com/mtdcy/cmdlets/main/cmdlets.sh

if curl --fail -sIL -o /dev/null https://git.mtdcy.top; then
    BASE=https://git.mtdcy.top/mtdcy/cmdlets/raw/branch/main/cmdlets.sh
fi

error() { echo -ne "\\033[31m$*\\033[39m"; }
info()  { echo -ne "\\033[32m$*\\033[39m"; }
warn()  { echo -ne "\\033[33m$*\\033[39m"; }

case "$OSTYPE" in
    darwin*)
        ARCH="$(uname -m)-apple-darwin"
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

usage() {
    cat << EOF
Copyright (c) 2024, mtdcy.chen@gmail.com

cmdlets.sh action [parameter(s)]

Supported actions:
    install <cmdlet>    - install cmdlet.
EOF
}

# pull cmdlet from server
pull() {
    # accept ENV:CMDLETS_ARCH
    local arch="${CMDLETS_ARCH:-$ARCH}"
    local dest="$arch/app/$1"
    if curl --fail -s -o "/tmp/$1-revision" "$REPO/$dest/revision"; then
        info "Pull applet $1 => $dest\n"

        local sha pkgname
        IFS=' ' read -r sha pkgname _ <<< "$(tail -n1 /tmp/$1-revision)"

        mkdir -p "$ROOT/$dest"
        curl --fail -# "$REPO/$dest/$pkgname" | tar -C "$ROOT/$dest" -xz

        chmod a+x "$ROOT/$dest/$1"
    elif curl --fail -s -o /dev/null -I "$REPO/$arch/bin/$1"; then
        dest="$arch/bin/$1"
        info "Pull cmdlet $1 => $dest\n"

        mkdir -p "$(dirname "$ROOT/$dest")"
        curl --fail -# -o "$ROOT/$dest" "$REPO/$dest"

        chmod a+x "$ROOT/$dest"
    else
        error "Pull $1 failed\n"
        return 1
    fi
}

install() {
    local dest tmpfile

    dest="$(which cmdlets.sh 2>/dev/null | xargs dirname)"
    if [ -z "$dest" ]; then
        [[ "$PATH" =~ $HOME/.bin ]] && dest="$HOME/.bin" || dest="/usr/local/bin"
    fi

    info "Install cmdlets => $dest\n"
    tmpfile="/tmp/$$-cmdlets.sh"
    curl --fail -# -o "$tmpfile" "$BASE"
    chmod a+x "$tmpfile"
    if [ -w "$dest" ]; then
        mv -f "$tmpfile" "$dest/cmdlets.sh"
    else
        sudo mv -f "$tmpfile" "$dest/cmdlets.sh"
    fi
}

name="$(basename "$0")"

if [ "$name" = "install" ] && [ $# -eq 0 ]; then
    install
    exit
elif [ "$name" = "fetch" ] && [ $# -eq 1 ]; then
    pull "$1"
    exit
elif [ "$name" = "cmdlets.sh" ]; then
    case "$1" in
        install)
            if [ -n "$2" ]; then # install cmdlets
                pull "$2"
                ln -sfv "$name" "$(dirname "$0")/$2"
            else
                install
            fi
            ;;
        help|*)
            usage
            ;;
    esac
    exit
fi

# preapre cmdlet
cmdlet="$ROOT/$ARCH/app/$name/$name"
[ -x "$cmdlet" ] || cmdlet="$ROOT/$ARCH/bin/$name"
[ -x "$cmdlet" ] || pull "$name"

# exec cmdlet
cmdlet="$ROOT/$ARCH/app/$name/$name"
[ -x "$cmdlet" ] || cmdlet="$ROOT/$ARCH/bin/$name"
[ -x "$cmdlet" ] || error "no cmdlet $name found.\n"

exec "$cmdlet" "$@"

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
