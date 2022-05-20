#!/bin/bash
APP_PATH=$(dirname $0)
echo "-> Apply patches"
cd /usr/lib/python3.10/site-packages/kvmd/
git apply ${APP_PATH}/*.patch
cd ${APP_PATH}
echo "-> Add otgmsd unlock link"
cp kvmd-helper-otgmsd-unlock /usr/bin/
echo "-> Apply old kernel msd patch done."