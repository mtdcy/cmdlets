# Distributed revision control system

# shellcheck disable=SC2034,SC2154
libs_lic=GPLv2
libs_ver=2.52.0
libs_url="https://mirrors.edge.kernel.org/pub/software/scm/git/git-$libs_ver.tar.xz"
libs_sha=3cd8fee86f69a949cb610fee8cd9264e6873d07fa58411f6060b3d62729ed7c5
libs_dep=( zlib pcre2 libiconv expat curl )

is_darwin || libs_dep+=( openssl )

libs_args=(
    prefix="'$PREFIX'"

    # no /etc/gitconfig
    ETC_GITCONFIG=/no-etc-gitconfig

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
is_musl && libs_args+=( NO_REGEX=NeedsStartEnd )

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

    make "${libs_args[@]}"

    # standalone cmds: binaries and bash scripts
    local cmds=(
        # basic
        git git-daemon git-shell git-submodule git-sh-setup
        # core utils
        git-receive-pack git-upload-pack git-upload-archive
        # http
        git-http-backend git-http-fetch git-http-push
        # merge & difftool
        git-mergetool git-difftool--helper
        # https
        "git-remote-http:git-remote-https:git-remote-ftp:git-remote-ftps"
        # misc
        git-request-pull
    )

    make -C contrib/subtree "${libs_args[@]}"
    cmds+=( contrib/subtree/git-subtree )

    if is_darwin; then
        make -C contrib/credential/osxkeychain "${libs_args[@]}"
        cmds+=( contrib/credential/osxkeychain/git-credential-osxkeychain )
    else
        make -C contrib/credential/netrc "${libs_args[@]}"
        cmds+=( contrib/credential/netrc/git-credential-netrc )
    fi

    # git-sh-setup: NO_GETTEXT
    sed -i git-sh-setup                                 \
        -e '/git-sh-i18n/d'                             \
        -e 's/eval_gettextln/eval echo/g'               \
        -e 's/eval_gettext/eval echo/g'                 \
        -e 's/gettextln/echo/g'                         \
        || die "modify git-sh-setup failed."

    # git-mergetool:
    sed -i git-mergetool                                \
        -e 's/git-sh-setup/$(which git-sh-setup)/'      \
        -e '/git-mergetool--lib/r git-mergetool--lib'   \
        -e '/git-mergetool--lib/d'                      \
        || die "modify git-mergetool failed."

    # git-difftool--helper:
    #  #1. GIT_EXTERNAL_DIFF=echo git diff
    #  #2. git difftool --extcmd echo
    #  #3. git difftool --tool vscode
    sed -i git-difftool--helper                         \
        -e '/git-mergetool--lib/r git-mergetool--lib'   \
        -e '/git-mergetool--lib/d'                      \
        || die "modify git-difftool--helper failed."

    for x in "${cmds[@]}"; do
        IFS=':' read -r bin links <<< "$x"
        cmdlet.install "./$bin" "${bin##*/}" ${links//:/ }
    done

    # pack all git tools into one pkgfile
    cmdlet.pkgfile git bin/git bin/git-*

    # mergetools: env MERGE_TOOLS_DIR
    cmdlet.pkginst mergetools share/mergetools mergetools/*

    cmdlet.check git --version

    cmdlet.caveats << EOF
static built $(./git --version) without libexec or i18n

all tools are installed in and loaded from executable path

mergetools:
    git difftool and mergetool need mergetools from \$HOME/.mergetools:

    cmdlets.sh install mergetools
    cmdlets.sh link share/mergetools ~/.mergetools

    OR you can set MERGE_TOOLS_DIR env to where mergetools is.
EOF

    if is_darwin; then
        cmdlet.caveats << EOF

osxkeychain:
    git config --global credential.helper osxkeychain
EOF
    else
        cmdlet.caveats << EOF

netrc:
    git config --global credential.helper netrc
    touch ~/.netrc
EOF
    fi
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
