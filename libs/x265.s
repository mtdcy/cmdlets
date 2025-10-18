# x265 HEVC Encoder

# shellcheck disable=SC2034
libs_lic="GPL-2.0-only"
libs_ver=4.1
libs_url=http://ftp.videolan.org/pub/videolan/x265/x265_$libs_ver.tar.gz
libs_sha=a31699c6a89806b74b0151e5e6a7df65de4b49050482fe5ebf8a4379d7af8f29

HIGH_BIT_DEPTH=0

if is_arm64; then
    asm_args=( -DENABLE_ASSEMBLY=ON )

    is_darwin || asm_args+=(
        -DENABLE_ASSEMBLY=ON
        -DENABLE_NEON=ON 
        -DENABLE_NEON_DOTPROD=OFF
        -DENABLE_NEON_I8MM=OFF
        -DENABLE_SVE=ON
    )

    # homebrew set this for linux aarch64
    is_linux && asm_args+=( -DENABLE_SVE2=OFF )
else
    asm_args=(
        # https://bitbucket.org/multicoreware/x265_git/issues/559
        -DCMAKE_ASM_NASM_FLAGS=-w-macro-params-legacy
    )
fi

# cmake 4 workaround, from homebrew
# report AppleClang as Clang
libs_patches=(
    https://api.bitbucket.org/2.0/repositories/multicoreware/x265_git/diff/b354c009a60bcd6d7fc04014e200a1ee9c45c167
    https://api.bitbucket.org/2.0/repositories/multicoreware/x265_git/diff/51ae8e922bcc4586ad4710812072289af91492a8
)

# shellcheck disable=SC2015
# shellcheck disable=SC2164
libs_build() {
    # -static-libstdc++: force static libstdc++.a
    # -Wl,-Bsymbolic: fix relocation R_AARCH64_ADR_PREL_PG_HI21 against symbol `x265_entropyStateBits'
    is_darwin || export LDFLAGS+=" -static-libstdc++ -Wl,-Bsymbolic"

    main_args=(
        -DEXTRA_LINK_FLAGS=-L.
        -DENABLE_SHARED=OFF
        -DCMAKE_VERBOSE_MAKEFILE=ON
        "${asm_args[@]}"
    )

    # build high bits always as static
    mkdir -pv {8bit,10bit,12bit}

    if [ "$HIGH_BIT_DEPTH" -ne 0 ]; then
        main_args+=( 
            -DEXTRA_LIB=\"x265_main12.a\;x265_main10.a\"
            -DLINKED_12BIT=ON
            -DLINKED_10BIT=ON
        )

        high_args=(
            -DHIGH_BIT_DEPTH=ON
            -DEXPORT_C_API=OFF
            -DENABLE_CLI=OFF
            -DENABLE_SHARED=OFF
            "${asm_args[@]}"
        )

        is_arm64 || high_args+=(
        )
    
        # 12 bit
        (
            cd 12bit
            cmake "${high_args[@]}" -DMAIN12=ON ../source &&
            make x265-static &&
            mv libx265.a ../8bit/libx265_main12.a
        ) || return 1

        # 10bit
        (
            cd 10bit
            cmake "${high_args[@]}" -DENABLE_HDR10_PLUS=ON ../source &&
            make x265-static &&
            mv libx265.a ../8bit/libx265_main10.a
        ) || return 1
    fi

    # 8bit/main profile
    cd 8bit
    cmake "${main_args[@]}" ../source &&
    make x265-static || return 1

    if [ "$HIGH_BIT_DEPTH" -ne 0 ]; then
        mv libx265.a libx265_main.a 

        if is_darwin; then
            libtool -static -o libx265.a libx265_main.a libx265_main10.a libx265_main12.a
        else
            $AR -M <<- 'EOF'
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF
        fi || return 1
    fi

    # bugfix
    sed -i 's/-lgcc_s//g' x265.pc &&

    pkginst libx265 x265_config.h ../source/x265.h libx265.a x265.pc

    inspect make install

    # FIXME: we have problem to compile a static x265 executable
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
