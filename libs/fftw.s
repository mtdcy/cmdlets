# C routines to compute the Discrete Fourier Transform

# shellcheck disable=SC2034
libs_lic=GPLv2+
libs_ver=3.3.10
libs_url=https://fftw.org/fftw-3.3.10.tar.gz
libs_sha=56c932549852cddcfafdab3820b0200c7742675be92179e59e6215b340e26467
libs_dep=( )

libs_patches=(
    # Fix the cmake config file when configured with autotools, upstream pr ref, https://github.com/FFTW/fftw3/pull/338
    "https://github.com/FFTW/fftw3/commit/394fa85ab5f8914b82b3404844444c53f5c7f095.patch?full_index=1"
)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-threads

    --disable-doc

    --disable-shared
    --enable-static
)

# Not default yet: https://github.com/FFTW/fftw3/pull/315#issuecomment-2630106315
#  => won't work with arm linux, and related changes will be included in FFTW 3.3.11
is_darwin && is_arm64 && libs_args+=( --enable-armv8-cntvct-el0 )

# FFTW supports runtime detection of CPU capabilities, so it is safe to
# use with --enable-avx and the code will still run on all CPUs
is_intel && simd_args+=( --enable-sse2 --enable-avx --enable-avx2 )
# enable-sse2, enable-avx and enable-avx2 work for both single and double precision.
# long-double precision has no SIMD optimization available.

# openmp
is_darwin || libs_args+=( --enable-openmp )

libs_build() {
    # build default double precision

    configure "${simd_args[@]}"

    make

    pkgfile libfftw3 -- make.install bin_PROGRAMS= bin_SCRIPTS=

    cmdlet.install tools/fftw-wisdom

    cmdlet.check fftw-wisdom --version
}

# fftw requires aligned malloc, which is not ready on mingw
libs.depends ! is_mingw

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
