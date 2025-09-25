#!/bin/bash

export DEPENDENTS_ONLY=true

for pkg in libs/*.u; do
    [[ "$pkg" =~ /@ ]] && continue 

    pkg="$(basename "${pkg%.u}")"

    bash ulib.sh compile "$pkg"
done
