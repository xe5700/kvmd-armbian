#!/bin/bash
# PYTHON_VERSION=$( python3 -V | awk '{print $2}' | cut -d'.' -f1,2 )
APP_PATH=$(readlink -f $(dirname $0))
echo "-> Apply patches"
if [[ "$CUSTOM_KVMD_VERSION" -eq 1 ]]; then
    cd $PYTHONDIR_PIP/kvmd-$KVMD_VERSION-py${PYTHON_VERSION}.egg/
else
    cd $PYTHONDIR_PIP
fi
PATCH_VER=""
if [ `expr $KVMD_SV \>= 84` -eq 1 ] && [ `expr $KVMD_SV \<= 92` -eq 1 ]; then
      PATCH_VER="v3.84-v3.134"
fi
if [ `expr $KVMD_SV \>= 124` -eq 1 ] && [ `expr $KVMD_SV \<= 142` -eq 1 ]; then
      PATCH_VER="v3.124-v3.142"
fi
git apply ${APP_PATH}/${PATCH_VER}/*.patch
cd ${APP_PATH}
# echo "-> Add otgmsd unlock link"
# cp kvmd-helper-otgmsd-unlock /usr/bin/
echo "-> Add sudoer"
echo "kvmd ALL=(ALL) NOPASSWD: /usr/bin/kvmd-helper-otgmsd-unlock" >> /etc/sudoers.d/99_kvmd
echo "-> Apply old kernel msd patch done."