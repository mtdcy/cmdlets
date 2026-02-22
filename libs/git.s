# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
# Distributed revision control system

# shellcheck disable=SC2034,SC2154
libs_stable=1 # no auto update
libs_lic=GPLv2
libs_ver=2.52.0
libs_url="https://mirrors.edge.kernel.org/pub/software/scm/git/git-$libs_ver.tar.xz"
libs_sha=3cd8fee86f69a949cb610fee8cd9264e6873d07fa58411f6060b3d62729ed7c5
libs_deps=( zlib pcre2 libiconv expat curl )

is_darwin || libs_deps+=( openssl )

#is_mingw && libs_deps+=( libgnurx )

libs_args=(
    # no /etc/gitconfig
    -Dgitconfig=/no-etc-gitconfig

    # disabled features
    -Dperl=enabled      # need by netrc
    -Dgitweb=disabled
    -Dpython=disabled
    -Dgettext=disabled
    -Ddocs=''
    -Dtests=false
    -Dregex=disabled # system regex

    # contrib
    -Dcontrib=subtree
)

# helpers
if is_darwin; then
    libs_args+=( -Dcredential_helpers=osxkeychain )
elif is_mingw; then
    libs_args+=( -Dcredential_helpers=wincred )
else
    libs_args+=( -Dcredential_helpers=netrc )
fi

is_listed pcre2    libs_deps && libs_args+=( -Dpcre2=enabled         ) || libs_args+=( -Dpcre2=disabled     )
is_listed expat    libs_deps && libs_args+=( -Dexpat=enabled         ) || libs_args+=( -Dexpat=disabled     )
is_listed libiconv libs_deps && libs_args+=( -Diconv=enabled         ) || libs_args+=( -Diconv=disabled     )
is_listed openssl  libs_deps && libs_args+=( -Dhttps_backend=openssl ) || libs_args+=( -Dhttps_backend=auto )

#1. avoid hardcode PREFIX into git commands
#2. avoid system libexec
#       /Library/Developer/CommandLineTools/usr/bin/git'
#       /usr/lib/git-core
#
# exec-cmd.c:setup_path => GIT_EXEC_PATH > PATH
# => disable libexec and use PATH instead
libs_args+=( -Dlibexecdir='/no-git-libexec' )

libs_build() {
    #libs.requires libgnurx

    # always find tools in host
    sed -i '/Program Files/d' meson.build

    # posix winpthread instead win32 thread
    if is_posix; then
        sed -i '/win32\/pthread.c/d' meson.build
        rm -f compat/win32/pthread.h
    fi

    cargo.setup # libgitcore requires cargo/rust

    meson.setup

    meson.compile

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

    if is_darwin; then
        cmds+=( contrib/credential/osxkeychain/git-credential-osxkeychain )
    elif is_mingw; then
        cmds+=( contrib/credential/wincred/git-credential-wincred )
    else
        cmds+=( contrib/credential/netrc/git-credential-netrc )
    fi

    if ! is_mingw; then
        cmds+=( contrib/subtree/git-subtree )

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
    fi

    for x in "${cmds[@]}"; do
        IFS=':' read -r bin links <<< "$x"
        cmdlet.install "$bin" "${bin##*/}" ${links//:/ }
    done

    # pack all git tools into one pkgfile
    cmdlet.pkgfile git bin/git bin/git-*

    # mergetools: env MERGE_TOOLS_DIR
    cmdlet.pkginst mergetools share/mergetools ../mergetools/*

    cmdlet.check git

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

__END__
# cargo-meson.sh do not handle cargo target

--- src/cargo-meson.sh.orig	2026-02-20 20:12:52.005811118 +0800
+++ src/cargo-meson.sh	2026-02-20 20:13:25.055634498 +0800
@@ -33,7 +33,7 @@
 		LIBNAME=libgitcore.a;;
 esac

-if ! cmp "$BUILD_DIR/$BUILD_TYPE/$LIBNAME" "$BUILD_DIR/libgitcore.a" >/dev/null 2>&1
+if ! cmp "$BUILD_DIR/$CARGO_BUILD_TARGET/$BUILD_TYPE/$LIBNAME" "$BUILD_DIR/libgitcore.a" >/dev/null 2>&1
 then
-	cp "$BUILD_DIR/$BUILD_TYPE/$LIBNAME" "$BUILD_DIR/libgitcore.a"
+	cp "$BUILD_DIR/$CARGO_BUILD_TARGET/$BUILD_TYPE/$LIBNAME" "$BUILD_DIR/libgitcore.a"
 fi
