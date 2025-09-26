#!/bin/bash -e

DEPENDENTS="libs/ulib.dependents"

touch "$DEPENDENTS"

olist() {
    local head=()
    local tail=()
    for x in "$@"; do
        IFS=' ' read -r -a _deps <<< "$(bash ulib.sh _deps_get "$x")"

        for y in "${_deps[@]}"; do
            # have dependencies => append
            if [[ "$*" == *"$y"* ]]; then
                tail+=( "$x" )
                break
            fi
        done

        # OR prepend
        [[ "${tail[*]}" == *"$x"* ]] || head+=( "$x" )
    done
    echo "${head[@]}" "${tail[@]}"
}

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
        list=( "$(olist "${list[@]}")" )
       
        sed -i "/^$dep:/d" "$DEPENDENTS"

        echo "$dep:${list[*]}" | tee -a "$DEPENDENTS"
    done
    
    echo ""
done
