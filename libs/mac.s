
#
# shellcheck disable=SC2034
upkg_lic="3-Clause BSD"
upkg_ver=1085
upkg_url=https://monkeysaudio.com/files/MAC_${upkg_ver}_SDK.zip
upkg_sha=f8169319f2bbe86feaaf4e900154f6d7d9eb74ac712026c202719aebceee7ec0
upkg_zip_strip=0 # default: 1

upkg_args=(
    -DBUILD_SHARED=OFF
)

upkg_static() {
    cmake . && make && make install
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
