#!/bin/bash

set -eo pipefail

export LANG="${LANG:-en_US.UTF-8}"

export STRIP="${CMDLETS_STRIP:-1}"

REPO=https://pub.mtdcy.top/cmdlets/latest
BASE=https://raw.githubusercontent.com/mtdcy/cmdlets/main/cmdlets.sh

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
    library <libname>   - install library to current directory.
EOF
}

# pull cmdlet from server
pull() {
    # accept ENV:CMDLETS_ARCH
    local arch="${CMDLETS_ARCH:-$ARCH}"
    local dest="$arch/app/$1"
    if curl --fail -s -o "/tmp/$1-revision" "$REPO/$dest/$1-revision"; then
        info "Pull applet $1 => $dest\n"

        local sha pkgname
        IFS=' ' read -r sha pkgname _ <<< "$(tail -n1 /tmp/$1-revision)"

        mkdir -p "$ROOT/$dest"
        curl --fail -# "$REPO/$dest/$pkgname" | tar -C "$ROOT/$dest" -xz
        if [ "$STRIP" -ne 0 ] && which strip &>/dev/null; then
            find "$ROOT/$dest" -type f -exec strip -s {} \; 2>/dev/null
        fi

        chmod a+x "$ROOT/$dest/$1"
    elif curl --fail -s -o /dev/null -I "$REPO/$arch/bin/$1"; then
        dest="$arch/bin/$1"
        info "Pull cmdlet $1 => $dest\n"

        mkdir -p "$(dirname "$ROOT/$dest")"
        curl --fail -# -o "$ROOT/$dest" "$REPO/$dest"
        if [ "$STRIP" -ne 0 ] && which strip &>/dev/null; then
            strip -s "$ROOT/$dest"
        fi

        chmod a+x "$ROOT/$dest"
    else
        error "Pull $1 failed\n"
        return 1
    fi
}

# pull library to current directory
pull-library() {
    local arch="${CMDLETS_ARCH:-$ARCH}"

    if ! curl --fail -s -o "/tmp/$1-revision" "$REPO/$arch/$1-revision"; then
        info "Pull library $1 failed\n"
        return 1
    fi

    local sha libname
    IFS=' ' read -r sha libname _ <<< "$(tail -n1 /tmp/$1-revision)"
    curl --fail -# "$REPO/$arch/$libname" | tar -xz

    # update pkgconfig .pc
    find lib/pkgconfig -name "*.pc" -exec sed -e "s:^prefix=.*$:prefix=$PWD:" -i {} \;
}

install() {
    local dest tmpfile

    if curl --fail -sIL -o /dev/null https://git.mtdcy.top/mtdcy/cmdlets/; then
        BASE=https://git.mtdcy.top/mtdcy/cmdlets/raw/branch/main/cmdlets.sh
    fi

    if which cmdlets.sh &>/dev/null; then
        dest="$(dirname "$(which cmdlets.sh)")"
    elif [[ "$PATH" =~ $HOME/.bin ]]; then
        dest="$HOME/.bin"
    else
        dest="/usr/local/bin"
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
        library) # fetch libs
            pull-library "$2"
            ;;
        help|*)
            usage
            ;;
    esac
    exit
fi

# never resolve symbolic here
ROOT="$(cd "$(dirname "$0")"; pwd)/prebuilts"

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
