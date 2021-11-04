# KVMD-ARMBIAN
KVMD Install for armbian 
It support amglogic based tv box, tested on phicomm n1.
You should install armbian with debian buster or bullseye.
Then running this script to install pikvm.
Install scripts is fork from @srepac rasbian pikvm install script.

Original Script [https://kvmnerds.com/RPiKVM/install-pikvm-raspbian.sh]
## Step 1
- Flash armbian debian buster for your tv box or π
## Step 2
- Modify your dtb file to enable dtb feature.
## Step 3
git clone https://github.com/xe5700/kvmd-armbian.git
cd kvmd-armbian
./install-amglogic.sh
