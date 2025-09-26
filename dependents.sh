#!/bin/bash -e

DEPENDENTS="libs/ulib.dependents"

touch "$DEPENDENTS"

for pkg in libs/*.u; do
    [[ "$pkg" =~ /@ ]] && continue 

    pkg="$(basename "${pkg%.u}")"

    [ "$pkg" = ALL ] && continue

    IFS=' ' read -r -a deps <<< "$(bash ulib.sh _deps_get "$pkg")"

    bash ulib.sh ulogi "$pkg => ${deps[*]}"

    for dep in "${deps[@]}"; do
        IFS=' ' read -r -a list <<< "$(grep "^$dep:" "$DEPENDENTS" | cut -d: -f2)"

        # merge dependents 
        [[ "${list[*]}" == *"$pkg"* ]] || list+=( "$pkg" )

        # reorder dependents
        IFS=' ' read -r -a list <<< "$(bash ulib.sh _sort_by_depends "${list[@]}")"
       
        sed -i "/^$dep:/d" "$DEPENDENTS"

        echo "$dep:${list[*]}" | tee -a "$DEPENDENTS"
    done
    
    echo ""
done
