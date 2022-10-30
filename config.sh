export GIT_EXE="git"
export MIRROR_GITHUB="https://github.com"
export MIRROR_GITHUB_API="https://api.github.com"

export PIKVMREPO="https://files.pikvm.org/repos/arch/rpi4"
export PIKVMREPO_PKG="/"
#export PIKVMREPO=""
#export KVMD_VERSION="3.47" # LEGECY KVMD VERSION SUPPORTS MSD AND RUNNING ON DEBIAN BULLSEYE OR BUSTER WITHOUT PATCH

# export KVMD_VERSION=""
export CUSTOM_KVMD_VERSION=1 # If you want install lastest version of kvmd set to 0
export KVMD_VERSION="3.142" # LAST KVMD VERSION SUPPORTS PYTHON3.9 
export PIKVM_KEY="912C773ABBD1B584"
export USE_GPIO=0
export DEBIAN_PYTHON=1
export KVMDCACHE="/var/cache/kvmd"
export PKGINFO="${KVMDCACHE}/packages.txt"
export DOWNLOAD_FUNC="./libs/download_wget.sh"
export GIT_CLONE_WITH_DEPTH="--depth=1"
export USE_JANUS=0
export USE_CSI=0
#export HID_MODE="" # Allow otg, ch9329, arduino, bluetooth mode
export USE_MSD=0
export USE_UDEV=0
#export PLATFORM_PATCH # Apply patch for board platform