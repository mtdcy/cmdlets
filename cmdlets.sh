#!/bin/bash 
#
# shellcheck disable=SC2155

set -eo pipefail
export LANG="${LANG:-en_US.UTF-8}"

ARCH="${CMDLETS_ARCH:-}"

REPO=https://pub.mtdcy.top/cmdlets/latest
BASE=https://raw.githubusercontent.com/mtdcy/cmdlets/main/cmdlets.sh

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

usage() {
    cat << EOF
Copyright (c) 2025, mtdcy.chen@gmail.com

cmdlets.sh action [parameter(s)]

Supported actions:
    update              - update $(basename "$BASE")
    install <cmdlet>    - install cmdlet
    fetch   <cmdlet>    - fetch cmdlet from server
    library <libname>   - pull library from server
    package <pkgname>   - pull cmdlets and libraries from server
EOF
}

# pull cmdlet from server
cmdlet() {
    local revision="$(mktemp)"
    trap "rm -f $revision" EXIT

    # v2 cmdlet & applet 
    if curl --fail -sL -o "$revision" "$REPO/$1-revision"; then
        info "Pull $1 => $PREFIX\n"

        local sha pkgname
        IFS=' ' read -r sha pkgname _ <<< "$(tail -n1 "$revision")"

        mkdir -p "$PREFIX"
        curl --fail -# "$REPO/$pkgname" | tar -C "$PREFIX" -xz
    # v1 applet: deprecated
    elif curl --fail -sL -o "$revision" "$REPO/app/$1/$1-revision"; then
        info "Pull applet $1 => $PREFIX\n"

        local sha pkgname
        IFS=' ' read -r sha pkgname _ <<< "$(tail -n1 "$revision")"

        mkdir -p "$PREFIX/app/$1"
        curl --fail -# "$REPO/app/$1/$pkgname" | tar -C "$PREFIX/app/$1" -xz
        chmod a+x "$PREFIX/app/$1/$1"
    # v1 cmdlet: deprecated
    elif curl --fail -sIL -o /dev/null "$REPO/bin/$1"; then
        info "Pull cmdlet $1 => $PREFIX\n"

        mkdir -p "$PREFIX/bin"
        curl --fail -# -o "$PREFIX/bin/$1" "$REPO/bin/$1"
        chmod a+x "$PREFIX/bin/$1"
    else
        error "Pull $1 failed\n"
        return 1
    fi
}

# pull library from server
library() {
    local revision="$(mktemp)"
    trap "rm -f $revision" EXIT

    if curl --fail -s -o "$revision" "$REPO/$1-revision"; then

        local sha libname
        IFS=' ' read -r sha libname _ <<< "$(tail -n1 "$revision")"

        mkdir -p "$PREFIX"
        curl --fail -# "$REPO/$libname" | tar -C "$PREFIX" -xz

        # update pkgconfig .pc
        find "$PREFIX/lib" -name "*.pc" -exec sed -e "s:^prefix=.*$:prefix=$PREFIX:p" -i {} \;
    else
        info "Pull library $1 failed\n"
        return 1
    fi
}

# pull package from server
package() {
    local pkginfo="$(mktemp)"
    trap "rm -f $pkginfo" EXIT

    if curl --fail -sL -o "$pkginfo" "$REPO/$1/pkginfo"; then
        mkdir -p "$PREFIX"

        while read -r line; do
            [ -n "$line" ] || continue
            local sha filepath
            IFS=' ' read -r sha filepath _ <<< "$line"

            info "Pulling $(basename "$filepath") => $PREFIX\n"
            curl --fail -# "$REPO/$filepath" | tar -C "$PREFIX" -xz
        done < "$pkginfo"
    else
        info "Pull package $1 failed\n"
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
