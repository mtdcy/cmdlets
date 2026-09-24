# GNU File, Shell, and Text utilities

# shellcheck disable=SC2034
libs_stable=1

libs_name=coreutils
libs_lic=GPLv3+
libs_ver=9.12
libs_rev=1
libs_url=${LIBS_MIRROR_GNU:-https://ftpmirror.gnu.org/gnu}/coreutils/coreutils-9.12.tar.xz
libs_sha=a480198559733e9b3da999e90543ac6f888a2caa544d8d664c5a1f17e528e210
libs_dep=(gmp)

libs_args=(

    # disabled features
    --disable-acl
    --disable-assert
    --disable-xattr
    --without-selinux

    --disable-nls
    --without-libintl-prefix
    --without-libiconv-prefix
)

list_has libs_dep gmp       && libs_args+=(--with-libgmp)
list_has libs_dep openssl   && libs_args+=(--with-openssl)

# gnu utils (for bsd systems like darwin)
_utils=(ls sort uniq cut tr wc realpath)

# symlinks related
#  no symlinks for mingw
is_mingw || _utils+=(
    ln link unlink readlink
)

# make huge utils for windows
if is_cygwin || is_mingw; then
    _utils+=(
        # basic
        rm cp mv yes true false
        test '[' nohup
        mkdir mktemp mkfifo
        # print
        echo printf
        # path
        pwd basename dirname
        # files
        touch cat tee head tail od
        # misc
        uname sleep
    )
fi

is_cygwin && _utils+=(
    # user
    id who whoami users groups env
    # disk
    du df
    # perm
    chmod chown
)

# useful tools
_tools=(
    date # gnu/bsd 语法完全断层
    numfmt
    nproc
    # md5 and sha
    base32 base64 md5sum sha1sum sha256sum sha512sum
)

# GNU coreutils-9.12 added quoting to 'env' and 'printenv'. This has caused
# some unforeseen issues in some invocations. Use a patch from upstream which
# only quotes when standard output is not a terminal. See the following
# mailing list discussion:
# https://lists.gnu.org/archive/html/coreutils/2026-09/msg00061.html
libs_patches=(
    https://github.com/coreutils/coreutils/commit/782a1e5bc2090212273bb731dceee2cc2a071e54.patch?full_index=1
)

libs_build() {
    # disclaim rust coreutils
    cmdlet.disclaim 0.10.0

    # undefined symbol: __memset_explicit_chk
    # GLIBC 2.31 does NOT compatible with c23 or gnu23
    if is_glibc; then
        libs.requires -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0
    fi

    configure

    make

    cmdlet.pkginst coreutils bin \
        $(printf "src/%s " "${_utils[@]}")

    for x in "${_tools[@]}"; do
        cmdlet.install src/$x
    done
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
