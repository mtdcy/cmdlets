#!/bin/bash -e

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

export CMDLET_LOGGING="${CMDLET_LOGGING:-silent}"

# support prepare for multiple targets
export CMDLET_TARGET="${CMDLET_TARGET:-$(bash libs.sh target)}"

cmdlets=()
if test -n "$1"; then
    cmdlets=( "$1" ) # build single library manually
else
    IFS=' ' read -r -a cmdlets < <( bash libs.sh list.changed "$TARGET" )

    # build cmdlet and rdepends by default
    rdepends=1
fi

test -n "${cmdlets[*]}" || {
    info "*** no cmdlets, exit ***"
    exit 0
}

[[ "${cmdlets[*]}" =~ ALL ]] && cmdlets=( $(bash libs.sh depends ALL) ) || true

info "*** prepare ${cmdlets[*]} ***"

if [[ "$cmdlets" =~ -$ ]]; then
    bash libs.sh fetch $(bash libs.sh depends "${cmdlets[@]%-}") "${cmdlets[@]%-}"
elif [[ "$cmdlets" =~ \+$ ]] || test -n "$rdepends"; then
    bash libs.sh fetch "${cmdlets[@]%+}" $(bash libs.sh rdepends "${cmdlets[@]%+}")
else
    bash libs.sh fetch "${cmdlets[@]}"
fi
