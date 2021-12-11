# KVMD-ARMBIAN
KVMD Install for armbian 
It support amglogic and rockchip based tv box, tested on phicomm n1, mxq pro 4k.
You should install armbian with debian buster or bullseye.
Then running this script to install pikvm.
Install scripts is fork from @srepac rasbian pikvm install script.

Original Script [https://kvmnerds.com/RPiKVM/install-pikvm-raspbian.sh]
## Step 1
- Flash armbian debian buster for your tv box or π
## Step 2
- Modify your dtb file to enable dtb feature.
- If you use rk322x (rk3228A rk3228B rk3229) series chipset, you can use dtb/4.4/rk332x-box.dtb 
## Step 3
git clone https://github.com/xe5700/kvmd-armbian.git
cd kvmd-armbian
./install.sh
## Step 4
- running install.sh after reboot os
- Enjoy