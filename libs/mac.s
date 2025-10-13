
#
# shellcheck disable=SC2034
libs_lic="3-Clause BSD"
libs_ver=1085
libs_url=https://monkeysaudio.com/files/MAC_${libs_ver}_SDK.zip
libs_sha=f8169319f2bbe86feaaf4e900154f6d7d9eb74ac712026c202719aebceee7ec0

libs_args=(
    -DBUILD_SHARED=OFF
)

libs_build() {
    cmake . && make && make install
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
