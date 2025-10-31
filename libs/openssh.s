# OpenBSD freely-licensed SSH connectivity tools

# shellcheck disable=SC2034
libs_lic='SSH-OpenSSH'
libs_ver=10.2p1
libs_url=https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.2p1.tar.gz
libs_sha=ccc42c0419937959263fa1dbd16dafc18c56b984c03562d2937ce56a60f798b2
libs_dep=( ldns openssl libedit libxcrypt zlib )

# macOS: use libpam from host
is_linux && libs_dep+=( libpam )

libs_args=(
    --sysconfdir=/etc/ssh

    --with-ssl-dir="'$PREFIX'"
    --with-ldns="'$PREFIX'"
    --with-libedit
    --with-kerberos5
    --with-pam

    # fido2 ?
    --disable-security-key
    #--with-security-key-builtin
    #--enable-sk-internal
)

is_linux && libs_args+=( --with-privsep-path=/var/lib/sshd )

libs_build() {
    # no ldns-config present
    LIBS='-lcrypto'

    # fix static libpam
    is_linux && LIBS+=" $($PKG_CONFIG --libs-only-l pam)"

    export LIBS

    # openssh use PKGCONFIG instead of PKG_CONFIG
    export PKGCONFIG="$PKG_CONFIG"

    # from homebrew
    is_darwin && export CPPFLAGS+=" -D__APPLE_SANDBOX_NAMED_EXTERNAL__"

    # avoid hardcoded PREFIX in executables
    #  => this weaken sshd security, be careful
    RELATIVE_PATHS=(
        SSH_PROGRAM=ssh                         # ssh client, used by others like scp
        ASKPASS_PROGRAM=ssh-askpass             # ask pass from user, env: SSH_ASKPASS
        SSH_KEYSIGN=ssh-keysign                 # invoke by ssh client, conf: EnableSSHKeysign
        SSH_SK_HELPER=ssh-sk-helper             # invoke by ssh client, for authentication
        SSH_PKCS11_HELPER=ssh-pkcs11-helper     # invoke by ssh client, for PKCS#11 complient hardware tokens.
        SSHD_SESSION=sshd-session               # handles a single, individual ssh session on server
        SSHD_AUTH=sshd-auth                     # invoke by sshd, verify user's identity
        SFTP_SERVER=sftp-server
    )
    # check with:
    #  scp -vvvv file user@remote:~/ | grep prebuilts

    configure

    # server
    make sshd sshd-session sshd-auth "${RELATIVE_PATHS[@]}"
    pkginst sshd bin            \
                 sshd           \
                 sshd-auth      \
                 sshd-session   \

    # client tools
    make ssh ssh-keysign ssh-keygen ssh-add "${RELATIVE_PATHS[@]}"
    pkginst ssh bin             \
                ssh             \
                ssh-keysign     \
                ssh-keygen      \
                ssh-add         \

    # seperate pkgfiles
    pkgfile ssh-add     bin/ssh-add
    pkgfile ssh-keygen  bin/ssh-keygen
    pkgfile ssh-keysing bin/ssh-keysign

    # standalone tools
    make scp sftp "${RELATIVE_PATHS[@]}"
    cmdlet ./scp
    cmdlet ./sftp
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
