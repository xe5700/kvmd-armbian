#!/bin/bash
APP_PATH=$(readlink -f $(dirname $0))
echo "-> Apply patches"
if [[ "$CUSTOM_KVMD_VERSION" -eq 1 ]]; then
    cd $PYTHONDIR_PIP/kvmd-$KVMD_VERSION-py*.egg/
else
    cd $PYTHONDIR_PIP
fi
if [ `$KVMD_VERSION \>= 3.84 && $KVMD_VERSION \<= 3.92` -eq 1 ]; then
      PATCH_VER="v3.84-v3.134"
fi
if [ `$KVMD_VERSION \>= 3.124 && $KVMD_VERSION \<= 3.142` -eq 1 ]; then
      PATCH_VER="v3.124-v3.142"
fi
git apply ${APP_PATH}/${PATCH_VER}/*.patch
cd ${APP_PATH}
echo "-> Add otgmsd unlock link"
cp kvmd-helper-otgmsd-unlock /usr/bin/
echo "-> Add sudoer"
echo "kvmd ALL=(ALL) NOPASSWD: /usr/bin/kvmd-helper-otgmsd-unlock" >> /etc/sudoers.d/99_kvmd
echo "-> Apply old kernel msd patch done."