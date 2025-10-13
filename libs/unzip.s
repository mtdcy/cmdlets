# shellcheck disable=SC2034

upkg_name=unzip
upkg_desc="Extraction utility for .zip compressed archives"

upkg_lic='Info-ZIP'
upkg_ver=6.0
upkg_url=(
    https://downloads.sourceforge.net/project/infozip/UnZip%206.x%20%28latest%29/UnZip%20$upkg_ver/unzip${upkg_ver//\./}.tar.gz
)

upkg_zip_strip=1

upkg_sha=(
    036d96991646d0449ed0aa952e4fbe21b476ce994abc276e49d30e686708bd37
)

upkg_dep=(libiconv bzip2)

upkg_patch_url=(
    # patches from ubuntu: https://packages.ubuntu.com/kinetic/unzip
    http://archive.ubuntu.com/ubuntu/pool/main/u/unzip/unzip_6.0-28ubuntu6.debian.tar.xz
)

upkg_patch_sha=(
    7b124db7b04823549413ac8d5fadb9465f38530bebc24363e313351b7e1071fb
)

upkg_patches=(
    patches/01-manpages-in-section-1-not-in-section-1l.patch
    patches/02-this-is-debian-unzip.patch
    patches/03-include-unistd-for-kfreebsd.patch
    patches/04-handle-pkware-verification-bit.patch
    patches/05-fix-uid-gid-handling.patch
    patches/06-initialize-the-symlink-flag.patch
    patches/07-increase-size-of-cfactorstr.patch
    patches/08-allow-greater-hostver-values.patch
    patches/09-cve-2014-8139-crc-overflow.patch
    patches/10-cve-2014-8140-test-compr-eb.patch
    patches/11-cve-2014-8141-getzip64data.patch
    patches/12-cve-2014-9636-test-compr-eb.patch
    patches/13-remove-build-date.patch
    patches/14-cve-2015-7696.patch
    patches/15-cve-2015-7697.patch
    patches/16-fix-integer-underflow-csiz-decrypted.patch
    patches/17-restore-unix-timestamps-accurately.patch
    patches/18-cve-2014-9913-unzip-buffer-overflow.patch
    patches/19-cve-2016-9844-zipinfo-buffer-overflow.patch
    patches/20-cve-2018-1000035-unzip-buffer-overflow.patch
    patches/20-unzip60-alt-iconv-utf8.patch
    patches/21-fix-warning-messages-on-big-files.patch
    patches/22-cve-2019-13232-fix-bug-in-undefer-input.patch
    patches/23-cve-2019-13232-zip-bomb-with-overlapped-entries.patch
    patches/24-cve-2019-13232-do-not-raise-alert-for-misplaced-central-directory.patch
    patches/25-cve-2019-13232-fix-bug-in-uzbunzip2.patch
    patches/26-cve-2019-13232-fix-bug-in-uzinflate.patch
    patches/27-zipgrep-avoid-test-errors.patch
    patches/28-cve-2022-0529-and-cve-2022-0530.patch
    patches/handle_windows_zip64.patch
    patches/29-fix-troff-warning.patch
    patches/30-fix-code-pages.patch
    patches/CVE-2021-4217.patch
)

upkg_args=(
    CC="'$CC'"
    CFLAGS="'$CFLAGS $CPPFLAGS -DLARGE_FILE_SUPPORT -DUNICODE_SUPPORT -DUNICODE_WCHAR -DUTF8_MAYBE_NATIVE -DNO_WORKING_ISPRINT'"
    LF2="'$LDFLAGS -liconv'"
    D_USE_BZ2=-DUSE_BZIP2
    L_BZ2=-lbz2
)

# targets:
is_darwin && upkg_args+=(bsd) || upkg_args+=(unzips)

upkg_static() {
    make -f unix/Makefile "${upkg_args[@]}" V=1 &&
    
    make -f unix/Makefile check     &&

    cmdlet ./unzip unzip zipinfo    &&
    cmdlet ./unzipsfx               &&
    cmdlet ./funzip                 &&
    cmdlet ./unix/zipgrep           &&

    # verify
    check unzip
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
