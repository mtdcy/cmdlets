# Distributed revision control system

# shellcheck disable=SC2034,SC2154
libs_lic="GPL-2.0-only"
libs_ver=2.51.1
libs_url="https://mirrors.edge.kernel.org/pub/software/scm/git/git-$libs_ver.tar.xz"
libs_sha=a83fd9ffaed7eee679ed92ceb06f75b4615ebf66d3ac4fbdbfbc9567dc533f4a
libs_dep=( zlib pcre2 libiconv expat curl )

is_darwin || libs_dep+=( openssl )

libs_args=(
    prefix="'$PREFIX'"
    sysconfdir=/etc

    CC="'$CC'"
    CFLAGS="'$CFLAGS $CPPFLAGS'"
    LDFLAGS="'$LDFLAGS'"

    NO_GETTEXT=1 # no translation
    NO_PERL=1
    NO_GITWEB=1
    NO_PYTHON=1
    NO_TCLTK=1
    NO_FINK=1
    NO_DARWIN_PORTS=1

    # pcre2
    USE_LIBPCRE2=1
    # use our libiconv both for Linux and macOS
    NEEDS_LIBICONV=1
    
    INSTALL_SYMLINKS=1
)

is_darwin && libs_args+=(
    NO_OPENSSL=1
    APPLE_COMMON_CRYPTO=1
) || libs_args+=(
    NO_APPLE_COMMON_CRYPTO=1
)

# "Git requires REG_STARTEND support. Compile with NO_REGEX=NeedsStartEnd"
is_musl_gcc && libs_args+=( NO_REGEX=NeedsStartEnd )

#1. avoid hardcode PREFIX into git commands
#2. avoid system libexec
#       /Library/Developer/CommandLineTools/usr/bin/git'
#       /usr/lib/git-core
#
# exec-cmd.c:setup_path => GIT_EXEC_PATH > PATH
# => disable libexec and use PATH instead
libs_args+=( gitexecdir='/no-git-libexec' )

libs_build() {
    # no pkg-config outside libs_build

    # curl & expat for git-http-*
    libs_args+=(
        CURL_CFLAGS="'$($PKG_CONFIG --cflags libcurl)'"
        CURL_LDFLAGS="'$($PKG_CONFIG --libs libcurl)'"
        EXPAT_LIBEXPAT="'$($PKG_CONFIG --libs expat)'"
    )

    # git build system prefer hard link, disable it
    sed -i '/ln \$< \$@/d' Makefile || true

    make "${libs_args[@]}" || return 1

    # standalone cmds: binaries and bash scripts
    local cmds=(
        # basic
        git git-shell 
        # core utils
        git-receive-pack git-upload-pack git-upload-archive
        # http & https
        git-http-backend git-http-fetch git-http-push 
        # submodule
        git-submodule
        # mail
        git-imap-send
        # import
        git-quiltimport git-request-pull
    )

    make -C contrib/subtree "${libs_args[@]}" &&
    cmds+=( contrib/subtree/git-subtree ) &&

    if is_darwin; then
        cd contrib/credential/osxkeychain &&
        make "${libs_args[@]}"  &&
        cd - || return 2
        cmds+=( contrib/credential/osxkeychain/git-credential-osxkeychain )
    fi

    for x in "${cmds[@]}"; do
        cmdlet "./$x" || return 3
    done

    # specials
    cmdlet ./git-remote-http git-remote-http git-remote-https &&
    cmdlet ./git-remote-ftp  git-remote-ftp  git-remote-ftps  &&

    # bug fix: NO_GETTEXT
    sed -i git-sh-setup                     \
        -e '/git-sh-i18n/d'                 \
        -e 's/eval_gettextln/eval echo/g'   \
        -e 's/eval_gettext/eval echo/g'     \
        -e 's/gettextln/echo/g'             \
        &&

    cmdlet ./git-sh-setup                                     &&

    # pack all git tools into one pkgfile
    pkgfile git bin/git bin/git-*                             &&

    check git --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
