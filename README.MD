# KVMD-ARMBIAN
KVMD Install for armbian
It support Allwinner, Amlogic and Rockchip based tv box, tested on phicomm n1, mxq pro 4k, tqc a01. 
Chipset needs support USB OTG feature, lots of old amglogic chipset not support otg feature, such as s805 and s905.
You should install armbian with debian buster or bullseye.
Then running this script to install pikvm.
Install scripts is fork from @srepac rasbian pikvm install script.

Original Script [https://kvmnerds.com/RPiKVM/install-pikvm-raspbian.sh]

# Hardware for kvmd-armbian project
* A tv box supports otg feature:
    - Tests on phicomm n1(Amlogic s905d), mxq pro 4k (rk322x), tqc a01(Allwinner H6). 
* Video capture device:
    - HDMI to USB dongle (30 RMB On taobao, 10$ on aliexpress.)
      cheap hdmi to usb dongle all use physics USB2.0 port, but fake USB3.0(USB 5GBPS, USB3.2GEN1) version supports 720P 60FPS,
      usb 2.0 version only supports 720P 30FPS.
* USB-A to USB-A cable:
    - Recommended cut off usb cable's power line, it might causes otg disconnect.

## Step 1
- Flash armbian debian [Recommended bullseye] for your tv box (If kernel not support otg you should build a kernel enable otg features)
## Step 2
- Modify your dtb file to enable otg feature. Change dr_mode from host to peripheral for otg usb port.
- If you use rk322x (rk3228A rk3228B rk3229) series chipset, you can use dtb/4.4/rk332x-box.dtb 
## Step 3
git clone https://github.com/xe5700/kvmd-armbian.git
cd kvmd-armbian
./install.sh (If very slow, you can use install-mirror.sh to boost install speed.)
## Step 4
- running install.sh or install-mirror.sh after reboot os then running again.
- Enjoy