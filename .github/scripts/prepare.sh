#!/bin/bash -e

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

export CMDLET_LOGGING="${CMDLET_LOGGING:-silent}"

cmdlets=()
if test -n "$1"; then
    cmdlets=( "$1" ) # build single library manually
else
    TAG="$(bash libs.sh arch)"

    : "${OLDHEAD:="$(git tag -l "$TAG")"}"
    : "${OLDHEAD:="HEAD~1"}"

    OLDHEAD="$(git rev-parse "$OLDHEAD")"
    while read -r line; do
        # file been deleted or renamed
        test -e "$line" || continue

        # only top dir
        [ "${line%/*}" = "libs" ] && line="${line#*/}" || continue

        # excludes
        [[ "$line" =~ ^_ ]] || cmdlets+=( "${line%.s}" )
    done < <(git diff --name-only $OLDHEAD..HEAD | grep "^libs/.*\.s")

    # build cmdlet and rdepends by default
    rdepends=1
fi

#test -n "${cmdlets[*]}" || cmdlets=( $(bash libs.sh _deps_get ALL) )
test -n "${cmdlets[*]}" || {
    info "*** no cmdlets, exit ***"
    exit 0
}
    
cmdlets=( $(printf '%s\n' "${cmdlets[@]}" | sort -u) )

[[ "${cmdlets[*]}" =~ ALL ]] && cmdlets=( $(bash libs.sh _deps_get ALL) ) || true

info "*** prepare ${cmdlets[*]} ***"

if [[ "$cmdlets" =~ -$ ]]; then
    bash libs.sh fetch $(bash libs.sh depends "${cmdlets[@]%-}") "${cmdlets[@]%-}"
elif [[ "$cmdlets" =~ \+$ ]] || test -n "$rdepends"; then
    bash libs.sh fetch "${cmdlets[@]%+}" $(bash libs.sh rdepends "${cmdlets[@]%+}")
else
    bash libs.sh fetch "${cmdlets[@]}"
fi
