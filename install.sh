#!/bin/bash
# modified by xe5700 		2021-11-04	xe5700@outlook.com
# modified by NewbieOrange	2021-11-04
# created by @srepac   08/09/2021   srepac@kvmnerds.com
# Scripted Installer of Pi-KVM on Raspbian (32-bit) meant for RPi4
#
# *** MSD is disabled by default ***
#
# Mass Storage Device requires the use of a USB thumbdrive or SSD and will need to be added in /etc/fstab
: '
# SAMPLE /etc/fstab entry for USB drive with only one partition formatted as ext4 for the entire drive:

/dev/sda1  /var/lib/kvmd/msd   ext4  nodev,nosuid,noexec,ro,errors=remount-ro,data=journal,X-kvmd.otgmsd-root=/var/lib/kvmd/msd,X-kvmd.otgmsd-user=kvmd  0  0

'
# NOTE:  This was tested on a new install of raspbian desktop and lite versions, but should also work on an existing install.
#
# Last change 20210818 1830 PDT
# VER=1.0
source config.sh
source $DOWNLOAD_FUNC
set +x
APP_PATH=$(readlink -f $(dirname $0))
export KVMD_BV=`echo $KVMD_VERSION | awk '{print substr($1,1,1)}'`
export KVMD_SV=`echo $KVMD_VERSION | awk '{print substr($1,3)}'`

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "usage:  $0 [-f]   where -f will force re-install new pikvm platform"
  exit 1
fi

WHOAMI=$( whoami ) 
if [ "$WHOAMI" != "root" ]; then
  echo "$WHOAMI, please run script as root."
  exit 1
fi

press-enter() {
  echo 
  read -p "Press ENTER to continue or CTRL+C to break out of script."
} # end press-enter

gen-ssl-certs() {
  cd /etc/kvmd/nginx/ssl
  openssl ecparam -out server.key -name prime256v1 -genkey
  openssl req -new -x509 -sha256 -nodes -key server.key -out server.crt -days 3650 \
        -subj "/C=US/ST=Denial/L=Denial/O=Pi-KVM/OU=Pi-KVM/CN=$(hostname)"
  cp server* /etc/kvmd/vnc/ssl/
  cd ${APP_PATH}
} # end gen-ssl-certs

create-override() {
  if [ $( grep ^kvmd: /etc/kvmd/override.yaml | wc -l ) -eq 0 ]; then

    if [[ $( echo $platform | grep usb | wc -l ) -eq 1 ]]; then
      cat <<USBOVERRIDE >> /etc/kvmd/override.yaml
kvmd:
    hid:
        mouse_alt:
            device: /dev/kvmd-hid-mouse-alt  # allow absolute/relative mouse mode
    msd:
        type: disabled
    atx:
        type: disabled
    streamer:
        forever: true
        cmd_append:
            - "--slowdown"      # for usb dongle (so target doesn't have to reboot)
        resolution:
            default: 1280x720
USBOVERRIDE

    else

      cat <<CSIOVERRIDE >> /etc/kvmd/override.yaml
kvmd:
    hid:
        mouse_alt:
            device: /dev/kvmd-hid-mouse-alt
    msd:
        type: disabled
    streamer:
        forever: true
CSIOVERRIDE

    fi

  fi
} # end create-override

install-python-packages() {
pkgs=""
  for i in $( echo "aiofiles appdirs asn1crypto async-timeout bottle cffi chardet click 
colorama cryptography dateutil dbus dev hidapi idna libgpiod marshmallow more-itertools multidict netifaces 
packaging passlib pillow ply psutil pycparser pyelftools pyghmi pygments pyparsing requests semantic-version 
setproctitle setuptools six spidev systemd tabulate urllib3 wrapt xlib yaml yarl" )
  do
    pkgs="$pkgs python3-$i"
  done
  echo "-> Install python packages"
  $APT_EXE install $pkgs -y > /dev/null
  # U
  pip3 install dbus_next==0.2.3 zstandard==0.18.0 pyserial==3.5 aiohttp==3.8.3
} # end install python-packages

otg-devices() {
  modprobe libcomposite
  if [ ! -e /sys/kernel/config/usb_gadget/kvmd ]; then
    mkdir -p /sys/kernel/config/usb_gadget/kvmd/functions
    cd /sys/kernel/config/usb_gadget/kvmd/functions
    mkdir hid.usb0  hid.usb1  hid.usb2  mass_storage.usb0
  fi
  cd ${APP_PATH}
} # end otg-device creation

install-tc358743() {
  ### CSI Support for Raspbian ###
  wget -O- -q https://www.linux-projects.org/listing/uv4l_repo/lpkey.asc | apt-key add -
  echo "deb https://www.linux-projects.org/listing/uv4l_repo/raspbian/stretch stretch main" | tee /etc/apt/sources.list.d/uv4l.list

  apt-get update > /dev/null
  echo "$APT_EXE install uv4l-tc358743-extras -y" 
  $APT_EXE install uv4l-tc358743-extras -y > /dev/null
} # install package for tc358743

boot-files() { 
  if [[ $( grep srepac /boot/config.txt | wc -l ) -eq 0 ]]; then

    if [[ $( echo $platform | grep usb | wc -l ) -eq 1 ]]; then

      # Armbian does not support config.txt, remove it.

      # amlogic does not support CSI, skip the following
      # add the tc358743 module to be loaded at boot for CSI
      # if [[ $( grep -w tc358743 /etc/modules | wc -l ) -eq 0 ]]; then
      #   echo "tc358743" >> /etc/modules
      # fi

      # install-tc358743 
      :
    fi 
  fi  # end of check if entries are already in /boot/config.txt

  # Remove OTG serial (Orange pi zero's kernel not support it)
  sed -i '/^g_serial/d' /etc/modules 

  # /etc/modules required entries for DWC2, HID and I2C
  if [[ $( grep -w dwc2 /etc/modules | wc -l ) -eq 0 ]]; then
    echo "dwc2" >> /etc/modules
  fi
  if [[ $( grep -w libcomposite /etc/modules | wc -l ) -eq 0 ]]; then
    echo "libcomposite" >> /etc/modules
  fi
  if [[ $( grep -w i2c-dev /etc/modules | wc -l ) -eq 0 ]]; then
    echo "i2c-dev" >> /etc/modules
  fi

#  printf "\n/boot/config.txt\n\n"
#  cat /boot/config.txt
  printf "\n/etc/modules\n\n"
  cat /etc/modules
} # end of necessary boot files

get-packages() { 
  printf "\n\n-> Getting Pi-KVM packages from ${PIKVMREPO}\n\n"
  mkdir -p "${KVMDCACHE}"
  #echo "wget ${PIKVMREPO} -O ${PKGINFO}"
  rm -f "${PKGINFO}"
  download "${PIKVMREPO}${PIKVMREPO_PKG}" "${PKGINFO}"
  echo "import Pi-Kvm Repo Key"
  gpg --keyserver keyserver.ubuntu.com --recv-keys $PIKVM_KEY
  gpg -a --export $PIKVM_KEY | apt-key add -
  # Download each of the pertinent packages for Rpi4, webterm, and the main service
  pkgs=`egrep 'janus|kvmd' "${PKGINFO}" | grep -v sig | cut -d'>' -f1 | cut -d'"' -f2 | egrep -v 'fan|oled' | egrep 'janus|pi4|webterm|kvmd-[0-9]'`
  if [ $CUSTOM_KVMD_VERSION -eq 1 ]; then
    pkgs=`printf "$d" | egrep -v 'kvmd-[0-9]'`
  fi
  for pkg in $pkgs
  do
    rm -f "${KVMDCACHE}/$pkg.sig"
    download "${PIKVMREPO}/$pkg.sig" "${KVMDCACHE}/$pkg.sig"
    download "${PIKVMREPO}/$pkg ${KVMDCACHE}/$pkg gpg ${KVMDCACHE}/$pkg.sig"
  done

  echo
  echo "ls -l ${KVMDCACHE}"
  ls -l "${KVMDCACHE}"
  echo
} # end get-packages function

get-platform() {
  # tryagain=1
  # while [ $tryagain -eq 1 ]; do
  #   # amglogic tv box only has usb port, use usb dongle.
	# # printf "Choose which capture device you will use:\n\n  1 - USB dongle\n  2 - v2 CSI\n  3 - V3 HAT\n" 
  #   # read -p "Please type [1-3]: " capture
	# capture=1;

  # done
    case $USE_CSI in 
      0) platform="kvmd-platform-v2-hdmiusb-rpi4"; tryagain=0;;
      # 2) platform="kvmd-platform-v2-hdmi-rpi4"; tryagain=0;;
      1) platform="kvmd-platform-v3-hdmi-rpi4"; tryagain=0;;
      *) printf "\nTry again.\n"; tryagain=1;;
    esac
    echo
    echo "Platform selected -> $platform"
    echo
} # end get-platform


install-kvmd-pkgs() {
  cd /

  INSTLOG="${KVMDCACHE}/installed_ver.txt"; rm -f "$INSTLOG"
  date > $INSTLOG 

# # uncompress platform package first
#   for i in $( ls "${KVMDCACHE}/${platform}-*.tar.xz" )
#   do
#     echo "-> Extracting package $i into /" >> "$INSTLOG" 
#     tar -vxf "$i"
#   done

# then uncompress, kvmd-{version}, kvmd-webterm, and janus packages 
  for i in $( ls "${KVMDCACHE}/*.tar.xz" | egrep 'kvmd-[0-9]' )
  do
    echo "-> Extracting package $i into /" >> "$INSTLOG"
    tar -vxf $i
  done
  if [ $CUSTOM_KVMD_VERSION -eq 1 ]; then
  # Use custom kvmd version replace kvmd offical package
    rm "${KVMDCACHE}/kvmd-common.tar.gz"
    download "${KVMD_COMMON_PKG_URL}" "${KVMDCACHE}/kvmd-common.tar.gz"
    echo "-> Extracting common kvmd package into /" >> "$INSTLOG"
    tar -vxf "${KVMDCACHE}/kvmd-common.tar.gz"
    echo "-> Install custom version kvmd" >> "$INSTLOG"
    $APT_EXE install python3-setuptools -y
    rm "${KVMDCACHE}/kvmd.tar.gz"
    download ${MIRROR_GITHUB}/pikvm/kvmd/archive/refs/tags/v$KVMD_VERSION.tar.gz "${KVMDCACHE}/kvmd.tar.gz"
    mkdir -p ${KVMDCACHE}/kvmd-tmp
    tar axf "${KVMDCACHE}/kvmd.tar.gz" -C /tmp/kvmd-tmp
    cd "${KVMDCACHE}/kvmd-tmp/kvmd-$KVMD_VERSION/"
    ./setup.py install
    cd "$APP_PATH"
    rm -rf {KVMDCACHE}/kvmd-tmp
  fi
  cp bin/* /usr/bin/
# then uncompress, kvmd-{version}, kvmd-webterm, and janus packages 
  for i in $( ls ${KVMDCACHE}/*.tar.xz | egrep 'janus|webterm' )
  do
    echo "-> Extracting package $i into /" >> "$INSTLOG"
    tar xfJ "$i"
  done
  cd "${APP_PATH}"
} # end install-kvmd-pkgs

fix-udevrules() { 
  # for hdmiusb, replace %b with 1-1.4:1.0 in /etc/udev/rules.d/99-kvmd.rules
  sed -i -e 's+\%b+1-1.4:1.0+g' /etc/udev/rules.d/99-kvmd.rules
  echo
  cat /etc/udev/rules.d/99-kvmd.rules
} # end fix-udevrules

enable-kvmd-svcs() { 
  # enable KVMD services but don't start them
  echo "-> Enabling kvmd-nginx kvmd-webterm kvmd-otg and kvmd services, but do not start them."
  systemctl enable kvmd-nginx kvmd-webterm kvmd-otg kvmd 

  # in case going from CSI to USB, then disable kvmd-tc358743 service (in case it's enabled)
  if [[ $USE_CSI -eq 0 ]]; then
    systemctl disable --now kvmd-tc358743 
  else
    systemctl enable kvmd-tc358743 
  fi
} # end enable-kvmd-svcs 

build-ustreamer() {
  printf "\n\n-> Building ustreamer\n\n"
  # Install packages needed for building ustreamer source
  echo "$APT_EXE install -y libevent-dev libjpeg-dev libbsd-dev libgpiod-dev libsystemd-dev janus-dev janus"
  $APT_EXE install -y libevent-dev libjpeg-dev libbsd-dev libsystemd-dev
  if [[ $USE_GPIO -eq 1 ]]; then
    $APT_EXE install -y libgpiod-dev
  fi
  if [[ $USE_JANUS -eq 1 ]]; then
    $APT_EXE install -y janus-dev janus
  fi
  # Download ustreamer source and build it
  cd /tmp
  $GIT_EXE clone $GIT_CLONE_WITH_DEPTH "$MIRROR_GITHUB/pikvm/ustreamer"
  cd ustreamer/
  # if [[ $( uname -m ) == "aarch64" ]]; then
  #   make WITH_OMX=0 WITH_GPIO=1 WITH_SETPROCTITLE=1	# ustreamer doesn't support 64-bit hardware OMX 
  # else
  #   make WITH_OMX=1 WITH_GPIO=1 WITH_SETPROCTITLE=1	# hardware OMX support with 32-bit ONLY
  # fi
  make WITH_GPIO=$USE_GPIO WITH_SYSTEMD=1 WITH_JANUS=$USE_JANUS -j
  make install
  # kvmd service is looking for /usr/bin/ustreamer   
  ln -s /usr/local/bin/ustreamer /usr/bin/
} # end build-ustreamer 

install-dependencies() {
  echo
  echo "-> Installing dependencies for pikvm"

  apt-get update > /dev/null
  # for i in $( echo "" )
  # do
  #   echo "$APT_EXE install -y $i"
  #   $APT_EXE install -y $i > /dev/null
  # done
  echo "-> Install basic packages"
  $APT_EXE install -y nginx python3 bc expect v4l-utils gpiod dialog git python3-pip tesseract-ocr tesseract-ocr-chi-sim jq
  install-python-packages

  echo "-> Make tesseract data link"
  ln -s /usr/share/tesseract-ocr/*/tessdata /usr/share/tessdata

  echo "-> Install TTYD"
  $APT_EXE install -y ttyd
  if [ ! -e /usr/bin/ttyd ]; then
    # Build and install ttyd
    # cd /tmp
    # $APT_EXE install -y build-essential cmake git libjson-c-dev libwebsockets-dev
    # git clone --depth=1 https://github.com/tsl0922/ttyd.git
    # cd ttyd && mkdir build && cd build
    # cmake ..
    # make -j && make install
    # Install binary from GitHub
    arch=$(dpkg --print-architecture)
    latest=$(wget -q -O- $MIRROR_GITHUB_API/repos/tsl0922/ttyd/releases/latest | jq -r ".tag_name")
    if [ $arch = arm64 ]; then
      arch='aarch64'
    fi
    if [ $arch = amd64 ]; then
      arch='x86_64'
    fi
    wget "$MIRROR_GITHUB/tsl0922/ttyd/releases/download/$latest/ttyd.$arch" -O /usr/bin/ttyd
    chmod +x /usr/bin/ttyd
  fi

  echo "-> Install ustreamer"
  if [ ! -e /usr/bin/ustreamer ]; then
    # apt install ustreamer
    cd /tmp/
	  $APT_EXE install -y libevent-2.1-7 libevent-core-2.1-7 libevent-pthreads-2.1-7 build-essential
    # ### required dependent packages for ustreamer ###
    build-ustreamer
    cd ${APP_PATH}
  fi
} # end install-dependencies

python-pkg-dir() {
  # debian system python3 no alias
  # create quick python script to show where python packages need to go
  cat << MYSCRIPT > /tmp/syspath.py
#!$(which python3)
import sys
print (sys.path)
MYSCRIPT

  chmod +x /tmp/syspath.py

  PYTHONDIR_SYS=$( /tmp/syspath.py | grep packages | sed -e 's/, /\n/g' -e 's/\[//g' -e 's/\]//g' -e "s+'++g" | tail -1 )
  PYTHONDIR_PIP=$( python3 -c "import site; print(site.getsitepackages()[0])" )
} # end python-pkg-dir

fix-nginx-symlinks() {
  # disable default nginx service since we will use kvmd-nginx instead 
  echo
  echo "-> Disabling nginx service, so that we can use kvmd-nginx instead" 
  systemctl disable --now nginx

  # setup symlinks
  echo
  echo "-> Creating symlinks for use with kvmd python scripts"
  if [ ! -e /usr/bin/nginx ]; then ln -s /usr/sbin/nginx /usr/bin/; fi
  if [ ! -e /usr/sbin/python ]; then ln -s /usr/bin/python3 /usr/sbin/python; fi
  if [ ! -e /usr/bin/iptables ]; then ln -s /usr/sbin/iptables /usr/bin/iptables; fi
  # if [ ! -e /opt/vc/bin/vcgencmd ]; then mkdir -p /opt/vc/bin/; ln -s /usr/bin/vcgencmd /opt/vc/bin/vcgencmd; fi

  python-pkg-dir

  if [ ! -e $PYTHONDIR_PIP/kvmd ]; then
    # Debian python版本比 pikvm官方的低一些
    ln -s /usr/lib/python3.10/site-packages/kvmd* ${PYTHONDIR_PIP}
  fi
} # end fix-nginx-symlinks

fix-python-symlinks(){
    python-pkg-dir

  if [ ! -e $PYTHONDIR_PIP/kvmd ]; then
    # Debian python版本比 pikvm官方的低一些
    ln -s /usr/lib/python3.10/site-packages/kvmd* ${PYTHONDIR_PIP}
  fi
}

apply-custom-patch(){
  read -p "Do you want apply old kernel msd patch? [y/n]" answer
  case $answer in
    n|N|no|No)
      echo 'You skiped this patch.'
      ;;
    y|Y|Yes|yes)
      ./patches/custom/old-kernel-msd/apply.sh
      ;;
    *)
      echo "Try again.";;
  esac
}

fix-kvmd-for-tvbox-armbian(){
  # 打补丁来移除一些对armbian和电视盒子不太支持的特性
  python-pkg-dir
  if [[ "$CUSTOM_KVMD_VERSION" -eq 1 ]]; then
    cd $PYTHONDIR_PIP/kvmd-$KVMD_VERSION-py*.egg/
  else
    cd $PYTHONDIR_PIP
  fi

  # if [[ "$DEBIAN_PYTHON" -eq 1 ]]; then
    # if [ `$KVMD_VERSION < 3.134` -eq ]; then
    #   PATCH_VER="v3.90"
    # fi
    # if [ `$KVMD_VERSION \>= 3.134` -eq 1 ]; then
    #   PATCH_VER="v3.134"
    # fi
    # if [ ! -z "$PATCH_VER" ]; then
    #   $GIT_EXE apply ${APP_PATH}/patches/debian_python/$PATCH_VER/*.patch
    # fi
  # fi
  if [[ "$USE_GPIO" -eq 0 ]] && [[ "$KVMD_BV" -eq "3" ]] ; then
    PATCH_VER=""
    if [ `expr $KVMD_SV \<= 81` -eq 1 ]; then
      PATCH_VER="v3.47-v3.81"
    fi
    if [ `expr $KVMD_SV \>= 82` -eq 1 ] && [ `expr $KVMD_SV \<= 83` -eq 1 ]; then
      PATCH_VER="v3.82-v3.83"
    fi
    if [ `expr $KVMD_SV \>= 84` -eq 1 ] && [ `expr $KVMD_SV \<= 134` -eq 1 ]; then
      PATCH_VER="v3.84-v3.134"
    fi
    if [ ! -z "$PATCH_VER" ]; then
      $GIT_EXE apply ${APP_PATH}/patches/disable_gpio/$PATCH_VER/*.patch
    fi
  fi
  if [ `expr $KVMD_SV \>= 84` -eq 1 ] && [ `expr $KVMD_SV \<= 92` -eq 1 ]; then
      PATCH_VER="v3.84-v3.92"
      $GIT_EXE apply ${APP_PATH}/patches/genernal/$PATCH_VER/*.patch
  fi
  cd ${APP_PATH}
  read -p "Do you want to apply custom patches?  [y/n] " answer
  case $answer in
    n|N|no|No)
     return;
     ;;
    y|Y|Yes|yes)
     apply-custom-patch;
     return;
     ;;
    *)
     echo "Try again.";;
  esac
}

fix-webterm() {
  echo
  echo "-> Creating kvmd-webterm homedir"
  mkdir -p /home/kvmd-webterm
  chown kvmd-webterm /home/kvmd-webterm
  ls -ld /home/kvmd-webterm
} # end fix-webterm

create-kvmdfix() { 
  # Create kvmd-fix service and script
  cat <<ENDSERVICE > /lib/systemd/system/kvmd-fix.service
[Unit]
Description=KVMD Fixes
After=network.target network-online.target nss-lookup.target
Before=kvmd.service

[Service]
User=root
Type=simple
ExecStart=/usr/bin/kvmd-fix

[Install]
WantedBy=multi-user.target
ENDSERVICE

  cat <<SCRIPTEND > /usr/bin/kvmd-fix
#!/bin/bash
# Written by @srepac
# 1.  Properly set group ownership of /dev/gpio*
# 2.  fix /dev/kvmd-video symlink to point to /dev/video1 (Amglogic Device video0 is not usb device)
#
### These fixes are required in order for kvmd service to start properly
#
set -x
chgrp gpio /dev/gpio*
chmod 660 /dev/gpio*   ### this is required in case gpio (wiringpi) is installed
ls -l /dev/gpio*

ls -l /dev/kvmd-video
rm /dev/kvmd-video
# Need to use video0 for orange pi (if you don't, the video capture won't work)
ln -s video1 /dev/kvmd-video
SCRIPTEND

  chmod +x /usr/bin/kvmd-fix
} # end create-kvmdfix

set-ownership() {
  # set proper ownership of password files and kvmd-webterm homedir
  cd /etc/kvmd
  chown kvmd:kvmd htpasswd
  chown kvmd-ipmi:kvmd-ipmi ipmipasswd
  chown kvmd-vnc:kvmd-vnc vncpasswd
  chown kvmd-webterm /home/kvmd-webterm

  # add kvmd user to video group (this is required in order to use CSI bridge with OMX and h264 support)
  usermod -a -G video kvmd
} # end set-ownership

check-kvmd-works() {
  # check to make sure kvmd -m works before continuing
  invalid=1
  while [ $invalid -eq 1 ]; do
    kvmd -m
    read -p "Did kvmd -m run properly?  [y/n] " answer
    case $answer in
      n|N|no|No)
        echo "Please install missing packages as per the kvmd -m output in another ssh/terminal."
        ;;
      y|Y|Yes|yes)
        invalid=0	
        ;;
      *)
        echo "Try again.";;
    esac
  done
} # end check-kvmd-works

start-kvmd-svcs() {
  #### start the main KVM services in order ####
  # 1. nginx is the webserver
  # 2. kvmd-otg is for OTG devices (keyboard/mouse, etc..)
  # 3. kvmd is the main daemon
  systemctl restart kvmd-nginx kvmd-otg kvmd-webterm kvmd 
  # systemctl status kvmd-nginx kvmd-otg kvmd-webterm kvmd 
} # end start-kvmd-svcs

fix-motd() { 
  rm /etc/motd
  cp armbian/armbian-motd /usr/bin/
  sed -i 's/cat \/etc\/motd/armbian-motd/g' /lib/systemd/system/kvmd-webterm.service
  systemctl daemon-reload
  # systemctl restart kvmd-webterm
} # end fix-motd

# 安装armbian的包
armbian-packages() {
  mkdir -p /opt/vc/bin/
  #cd /opt/vc/bin
  # Install vcgencmd for armbian platform
  cp -rf armbian/opt/* /opt/vc/bin
  #cp -rf armbian/udev /etc/

  cd ${APP_PATH}
  # 
}	#end armbian-packages

### MAIN STARTS HERE ###
# Install is done in two parts
# First part requires a reboot in order to create kvmd users and groups
# Second part will start the necessary kvmd services
# added option to re-install by adding -f parameter (for use as platform switcher)
PYTHON_VERSION=$( python3 -V | awk '{print $2}' | cut -d'.' -f1,2 )
if [[ $( grep kvmd /etc/passwd | wc -l ) -eq 0 || "$1" == "-f" ]]; then
  printf "\nRunning part 1 of PiKVM installer script for Raspbian by @srepac\n"
  get-packages
  get-platform
  boot-files
  install-kvmd-pkgs
  create-override
  gen-ssl-certs
  fix-udevrules
  install-dependencies
  otg-devices
  armbian-packages
  systemctl disable --now janus
  fix-kvmd-for-tvbox-armbian
  
  # Fix paste-as-keys if running python 3.7
  if [[ $( python3 -V | awk '{print $2}' | cut -d'.' -f1,2 ) == "3.7" ]]; then
    sed -i -e 's/reversed//g' $PYTHONDIR/kvmd/keyboard/printer.py
  fi

  sync
  echo "-> Synced data, you can reboot system safety."
  printf "\n\nReboot is required to create kvmd users and groups.\nPlease re-run this script after reboot to complete the install.\n"
  # Ask user to press CTRL+C before reboot or ENTER to proceed with reboot
  press-enter
  reboot
else
  printf "\nRunning part 2 of PiKVM installer script for Raspbian by @srepac\n"
  fix-nginx-symlinks
  fix-python-symlinks
  fix-webterm
  fix-motd
  set-ownership 
  create-kvmdfix
  check-kvmd-works
  enable-kvmd-svcs
  start-kvmd-svcs

  sync
  printf "\nCheck kvmd devices\n\n" 
  ls -l /dev/kvmd*
  printf "\nYou should see devices for keyboard, mouse, and video.\n"

  printf "\nPoint a browser to https://$(hostname)\nIf it doesn't work, then reboot one last time.\nPlease make sure kvmd services are running after reboot.\n"
fi
