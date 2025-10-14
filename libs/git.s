# Distributed revision control system

# shellcheck disable=SC2034,SC2154
libs_lic="GPL-2.0-only"
libs_ver=2.51.0
libs_url="https://mirrors.edge.kernel.org/pub/software/scm/git/git-$libs_ver.tar.xz"
libs_sha=60a7c2251cc2e588d5cd87bae567260617c6de0c22dca9cdbfc4c7d2b8990b62
libs_dep=( zlib pcre2 libiconv expat curl )

is_darwin || libs_dep+=( openssl )

libs_args=(
    prefix="'$PREFIX'"
    sysconfdir=/etc

    CC="'$CC'"
    CFLAGS="'$CFLAGS'"
    LDFLAGS="'$LDFLAGS'"

    # use system config dir
    sysconfdir=/etc

    NO_GETTEXT=1 # no translation
    NO_PERL=1
    NO_GITWEB=1
    NO_PYTHON=1
    NO_TCLTK=1
    NO_FINK=1
    NO_DARWIN_PORTS=1

    # 
    USE_LIBPCRE2=1
    LIBPCREDIR="'$PREFIX'"
    
    INSTALL_SYMLINKS=1

    # curl & expat for git-http-*
    EXPATDIR="'$PREFIX'"
    CURLDIR="'$PREFIX'"
    CURL_CFLAGS="'$($PKG_CONFIG --cflags libcurl)'"
    CURL_LDFLAGS="'$($PKG_CONFIG --libs libcurl)'"

    # iconv is required except for glibc
    NEEDS_LIBICONV=1
    ICONVDIR="'$PREFIX'"
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
    #make configure && configure || return 1

    # git build system prefer hard link, disable it
    sed -i '/ln \$< \$@/d' Makefile || true

    make "${libs_args[@]}" || return 1

    # standalone cmds
    local cmds=(
        # basic
        git git-shell git-sh-setup git-sh-i18n
        # core utils
        git-cvsserver git-receive-pack git-upload-pack git-upload-archive
        # http & https
        git-http-backend git-http-fetch git-http-push 
        # submodule
        git-submodule
        # mail
        git-imap-send git-send-email
        # import
        git-archimport git-cvsimport git-quiltimport git-request-pull
    )

    if is_darwin; then
        cd contrib/credential/osxkeychain &&
        make CC="'$CC'" CFLAGS="'$CFLAGS'" LDFLAGS="'$LDFLAGS'"  &&
        cd - || return 2
        cmds+=( contrib/credential/osxkeychain/git-credential-osxkeychain )
    fi

    for x in "${cmds[@]}"; do
        cmdlet "./$x" || return 3
    done

    # specials
    cmdlet ./git-remote-http git-remote-http git-remote-https &&
    cmdlet ./git-remote-ftp  git-remote-ftp  git-remote-ftps  &&

    # pack all git tools into one pkgfile
    pkgfile git bin/git bin/git-*                             &&

    check git --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
