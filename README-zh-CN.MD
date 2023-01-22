# 硬件准备

## 开发版选择 

建议选择能刷比较新的armbian的开发版作为PI-KVM

##### 1.选择原生带有OTG的开发版 例如:

- Orange Pi Prime(貌似已停产)

- Orange Pi Zero(需要制作一分二数据线 性能比较差 适合低成本1080P 30FPS方案)

- Orange Pi Zero LTS(和Orange Pi Zero一样)
  - 等其他 未列举完

##### 2.选择非原生支持修改dtb来实现OTG功能的开发版 例如:

- King 3399 (1个USB3.0 和一个Type-c 3.0做为OTG 能够满足1080P 60FPS方案)

- phicomm n1 (理论可以 把刷机那USB作为OTG 未做测试 不建议购买 性价比并不高)
  - 等其他 未列举完 

## 视频采集设备选择 HDMI转USB

- 如果你的开发版只有USB 2.0 建议选择ms2109 而且价格便宜 tb 30 RMB左右的即可

- 如果你的开发版有USB 3.0 建议选择ms2130 淘宝偏贵点 可输出1080P 60FPS
  - 以上设备我都已测试可以用 但是 部分主板可能使用这两款视频采集设备都会导致进BIOS颜色输出有问题(又不是不能用)

- 其他的视频采集设备也可以 你可以试试???

## OTG数据线准备

- 开发版OTG口为单独的Type-C口或Micro USB 那么 你只需要准备一根数据线即可
- 开发版OTG口为开发版供电 你需要手动制作一分二数据线 如下图

![1to2](https://raw.githubusercontent.com/toss-a/pikvm-armbian/master/1to2.png)

- 开发版OTG口为USB 修改dtb后实现的  你需要准备USB-A 转 USB-A 线缆

  建议切断 USB 线的电源线，它可能会导致 OTG 断开连接。

#### 第一步

- 刷入 armbian 用于您的开发版或电视盒（如果内核不支持 otg，您应该构建一个启用 otg 功能的内核）
- 如果你的开发版或者电视机或者支持从SD卡启动或者U盘启动 那么你需要把armbian写入到可移动存储介质上,写入完成后将一部分空闲分区划分为10G左右的空间格式化为EXT4 作为PI KVM 镜像储存分区(可选 非必须)

#### 第二步

- 修改您的 dtb 文件以启用 otg 功能。对于 otg USB 端口，将 dr_mode 从host更改为peripheral。
- 修改方法(Linux 推荐 Ubuntu)
  - sudo apt install device-tree-compiler
  - dtc 你开发版dtb -I dtb -O dts -o 输出的名称.dts
  - 修改 将dr_mode = "host" 修改为dr_mode = "peripheral"
  - dtc 刚刚修改的dts.dts -I dts -O dtb -o 你开发版.dtb
  - 替换,然后重启你的开发版

#### 第三步

- ```
  git clone https://github.com/toss-a/pikvm-armbian.git
  cd pikvm-armbian
  ./install.sh
  ```

- 我们内核比较新 不需要 所以按n
- 重启

#### 第四步

- 重启后再次运行刚刚运行的./install.sh
- 安装完成!!!

#### 启用大容量存储设备

需要格式化为EXT4

- 1.开发版或电视盒从U盘或者SD卡启动 使用内置emmc做为PI KVM 镜像存储
- 2.在armbian启动之前划分了PI KVM 镜像存储分区
- 3.再插入一个SD卡或U盘格式化为EXT4做为PI KVM 镜像存储



- 修改挂载点

  - ```
    vim /etc/fstab
    ```

  - 添加(/dev/sda1需要修改为你的存储介质dev路径)

  - ```
    /dev/sda1  /var/lib/kvmd/msd   ext4  nodev,nosuid,noexec,ro,errors=remount-ro,data=journal,X-kvmd.otgmsd-root=/var/lib/kvmd/msd,X-kvmd.otgmsd-user=kvmd  0  0
    ```

  - ```
    vim /etc/kvmd/override.yaml
    ```

  - 删除以下两行

  - ```
    msd:
    type:disable
    ```

  - 重启

#### 修复重启后视频采集设备无法采集到视频

- 1.以root用户登陆后克隆

- ```
  git clone https://github.com/jkulesza/usbreset
  ```

- 2.打开克隆的目录

- ```
  cd usbreset
  ```

- 3.将源码编译成可执行文件(如果报错请安装gcc)

- ```
  cc usbreset.c -o usbreset
  ```

- 4.赋予可执行权限

- ```
  chmod +x usbreset
  ```

- 4.获取需要重置的视频采集设备的总线和设备 ID

- ```
  lsusb
  ```

  - 我的输出内容为输出：

  - ```
  root@king3399:~# lsusb
  Bus 002 Device 002: ID 345f:2130 UltraSemi USB3 Video
  Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
  Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
  Bus 004 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
  Bus 003 Device 003: ID 0c45:768a Microdia USB DEVICE
  Bus 003 Device 002: ID 05e3:0608 Genesys Logic, Inc. Hub
  Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
  Bus 005 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
  Bus 006 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
  root@king3399:~#
  ```

- 5.尝试重启你的视频采集设备(我的设备为UltraSemi USB3 Video 对应为002/002)

- ```
  ./usbreset /dev/bus/usb/002/002
  ```

- 6.成功重启USB设备后添加到开机自启动

- ```
  vim /etc/rc.local
  ```

  - 添加内容

  - ```
  sleep 5
  /root/usbreset /dev/bus/usb/002/002
  ```

- 7.重启开发版再次查看

#### 更改PI KVM 登陆密码

- ```
  kvmd-htpasswd set admin
  ```

- 输入你需要的密码即可

#### 感谢,如果没有他们我不可能做到
- kvmd-armbian

  - [xe5700](https://github.com/xe5700/kvmd-armbian)

- [peacokswiss](https://github.com/xe5700/kvmd-armbian/issues/12)

- armkvm

  - [wxjiyc](https://github.com/wxjiyc/amlogic-s9xxx-armbian/blob/main/rebuild#L629)
  
- usbreset

  - [usbreset](https://github.com/jkulesza/usbreset)