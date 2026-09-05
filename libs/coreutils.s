# GNU File, Shell, and Text utilities

# shellcheck disable=SC2034
libs_stable=1

libs_name=coreutils
libs_lic=GPLv3+
libs_ver=9.11
libs_rev=1
libs_url=(
    https://mirrors.aliyun.com/gnu/coreutils/coreutils-9.11.tar.xz
    https://ftpmirror.gnu.org/gnu/coreutils/coreutils-9.11.tar.xz
)
libs_sha=394024eda0a5955217ceda9cd1201e65dc8fa3aa29c2951135a49521d57c3cc3
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

libs_build() {
    # disclaim rust coreutils
    cmdlet.disclaim 0.10.0

    configure

    make

    cmdlet.pkginst coreutils bin \
        $(printf "src/%s " "${_utils[@]}")

    for x in "${_tools[@]}"; do
        cmdlet.install src/$x
    done
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
