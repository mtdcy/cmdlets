#!/usr/bin/env bash

: "${REPO:=https://pub.mtdcy.top/cmdlets/latest}"

arch() {
    case "$(uname -s)" in
        Darwin)     echo "$(uname -m)-apple-darwin"         ;;
        msys)       echo "$(uname -m)-msys-${MSYSTEM,,}"    ;;
        *)          echo "$(uname -m)-linux-gnu"            ;;
    esac
}

: "${ARCH:=$(arch)}"

: "${PREFIX:=$PWD/prebuilts/$ARCH}"

: "${MANIFEST:=$PREFIX/cmdlets.manifest}"

info()  { echo -e "\\033[32m$*\\033[39m" 1>&2; }
warn()  { echo -e "\\033[33m$*\\033[39m" 1>&2; }

# v3/git releases
is_flat() { [[ "$REPO" =~ ^flat+ ]]; }

# fetch pkgfile to destination
fetch() (
    local dest

    test -n "$2" && dest="$2" || dest="$TEMPDIR/${1##*/}"

    mkdir -p "${dest%/*}"

    if is_flat; then
        info "== curl < $REPO/$ARCH/${1##*/}"
        curl -fsSL -o "$dest" "${REPO#flat+}/$ARCH/${1##*/}" || return 1
    else
        info "== curl < $REPO/$ARCH/$1"
        curl -fsSL -o "$dest" "$REPO/$ARCH/$1" || return 1
    fi

    if [[ "$dest" =~ tar.gz$ ]]; then
        tar -C "$PREFIX" -xvf "$dest"
    fi
)

# fetch package files
package() {
    local pkgname pkgvern pkginfo pkgfiles

    # priority: v2 > v3, no v1 package

    info "\n📦 Fetch package $1"

    # zlib@1.3.1
    IFS='@' read -r pkgname pkgvern <<< "$1"

    # v2: latest version
    : "${pkgvern:=latest}"

    pkginfo="$pkgname/pkginfo@$pkgvern"

    # prefer v2 pkginfo than v3 manifest for developers
    if ! is_flat && fetch "$pkginfo"; then
        # v2: 98945d2bc86df9be328fc134e4b8bc2254aeacf1d5050fc7b3e11942b1d00671 zlib/libz@1.3.1.tar.gz
        IFS=' ' read -r -a pkgfiles < <( grep -oE " $pkgname/.*@[0-9.]+\.tar\.gz" "$TEMPDIR/pkginfo@$pkgvern" | xargs )
    else
        # v3: libz zlib/libz@1.3.1.tar.gz 7de3e57ccdef64333719f70e6523154cfe17a3618d382c386fe630bac3801bed build=1

        # v3: no pkgvern => find out latest version
        if test -z "$pkgvern" || [ "$pkgvern" = "latest" ]; then
            IFS='/@' read -r  _ _ pkgvern _ < <( grep -oE " $pkgname/.*@[0-9.]+" "$MANIFEST" | sort -n | tail -n1 | sed 's/\.$//' )
            info ">> found package $pkgname@$pkgvern"
        fi

        # find all pkgfiles
        IFS=' ' read -r -a pkgfiles < <( grep -oE " $pkgname/.*@$pkgvern\.tar\.gz " "$MANIFEST" | xargs )
    fi

    test -n "${pkgfiles[*]}" || { warn "<< $* no pkgfile found"; return 1; }

    for x in "${pkgfiles[@]}"; do
        fetch "$x" || { warn "<< fetch $x failed"; return 1; }
    done

    touch "$PREFIX/.$pkgname.d" # mark as ready
}

if test -z "$TEMPDIR"; then
    TEMPDIR="$(mktemp -d)"
    trap 'rm -rf $TEMPDIR' EXIT
fi

# always fetch manifest
info "📦 Fetch $MANIFEST"
fetch cmdlets.manifest "$MANIFEST"

ret=0
for x in "$@"; do
    package "$x" || ret=$?
done

exit "$ret"
