#!/usr/bin/env bash

: "${REPO:=https://pub.mtdcy.top/cmdlets/latest}"

_arch() {
    case "$(uname -s)" in
        Darwin)     echo "$(uname -m)-apple-darwin"         ;;
        msys)       echo "$(uname -m)-msys-${MSYSTEM,,}"    ;;
        *)          echo "$(uname -m)-linux-gnu"            ;;
    esac
}
: "${ARCH:=$(_arch)}"

: "${PREFIX:=prebuilts/$ARCH}"

info()  { echo -e "\\033[32m$*\\033[39m" 1>&2; }
warn()  { echo -e "\\033[33m$*\\033[39m" 1>&2; }

_pkgfile() {
    echo "$PREFIX/$1"
}

# v3/git releases
_flat() { [[ "$REPO" =~ ^flat+ ]]; }

# fetch pkgfile to PREFIX
_fetch() (
    local dest="$(_pkgfile "$1")"
    local opts=( "${@:2}" )

    mkdir -p "${dest%/*}"

    if _flat; then
        info "== curl < $REPO/$ARCH/${1##*/}"
        curl -fsSL "${opts[@]}" -o "$dest" "${REPO#flat+}/$ARCH/${1##*/}" || return 1
    else
        info "== curl < $REPO/$ARCH/$1"
        curl -fsSL "${opts[@]}" -o "$dest" "$REPO/$ARCH/$1" || return 1
    fi

    if [[ "$dest" =~ tar.gz$ ]]; then
        tar -C "$PREFIX" -xvf "$dest"
    fi
)

# fetch package files
pkgfile() {
    local pkgname pkgvern pkginfo pkgfiles

    # priority: v2 > v3, no v1 package

    info "📦 Fetch package $1"

    # zlib@1.3.1
    IFS='@' read -r pkgname pkgvern <<< "$1"

    # v2: latest version
    : "${pkgvern:=latest}"

    pkginfo="$pkgname/pkginfo@$pkgvern"

    # prefer v2 pkginfo than v3 manifest for developers
    if ! _flat && _fetch "$pkginfo"; then
        # sha pkgfile ...
        IFS=' ' read -r -a pkgfiles < <( cut -d' ' -f2 < "$(_pkgfile "$pkginfo")" | xargs )
    else
        # v3: no latest => find out latest version
        if test -z "$pkgvern" || [ "$pkgvern" = "latest" ]; then
            # v3: libz zlib/libz@1.3.1.tar.gz
            IFS=' /@.' read -r _ _ _ pkgvern _ < <( grep " $pkgname/" "$MANIFEST" | tail -n1)
        fi

        # find all pkgfiles
        IFS=' ' read -r -a pkgfiles < <( grep " $pkgname/.*@$pkgvern" "$MANIFEST" | cut -d' ' -f2 | xargs)
    fi

    test -n "${pkgfiles[*]}" || { warn "<< $* no pkgfile found"; return 1; }

    for x in "${pkgfiles[@]}"; do
        _fetch "$x" || { warn "<< fetch $x failed"; return 1; }
    done

    touch "$PREFIX/.$pkgname.d" # mark as ready

    echo ""
}

# always fetch manifest
export MANIFEST="$(_pkgfile cmdlets.manifest)"
_fetch cmdlets.manifest

ret=0
for x in "$@"; do
    pkgfile "$x" || ret=$?
done

exit "$ret"
