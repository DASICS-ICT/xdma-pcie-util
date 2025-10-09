# Xilinx XDMA-PCIe utility tool for NEXST
## 简介

本工具从[NEXST](https://github.com/DASICS-ICT/nexst)内抽出整理而成，是用于NEXST生成bit（基于Xilinx xdma ip，使用PCIe与host连接）的FPGA上板测试工具。

## 使用方法

### 环境搭建
1. 搭建基于NEXST的FPGA硬件环境（PCIe/jtag连接FPGA板卡与host），确定PCIe/jtag连接正常。
2. 准备host的软件环境（例如vivado，此处略）。如果用户第一次将该工具用于本流程上板，请运行如下命令。
    ```bash
    make init_usergroup
    ```
   该脚本建立**xdma**用户组，并设置udev规则，将xdma设备放入用户组内，并将当前用户放入用户组。该步骤目的主要是便于fpgabot的用户信息识别，并且仅测试软件时可以不需要root权限完成上板。
3. 在EDA上使用NEXST环境生成用于上板的硬件bit流与配套软件bin，软件bin包含bootrom和workload（如bootloader+Linux Kernel，可以根据测试灵活更换）。可以使用如下命令将所需的软硬件payload从远端EDA拷贝到本工作区的`remote`文件夹。
    ```bash
    make fetch_remote EDA_HOST=${EDA_HOST_IP} PATH_TO_NEXST=${PATH_TO_NEXST_ON_EDA}
    # 使用的EDA用户名默认为当前host执行命令的用户名
    # 可以使用fetch_remote_hw / fetch_remote_sw 只传输硬件/软件payload
    ```
4. 准备xdma驱动的`xdma.ko`文件。使用NEXST工作流编译的xdma驱动位于`${PATH_TO_NEXST_ON_EDA}/shell/software/build/xdma_drv/`目录下，只要编译时host使用的kernel和上板时host使用的kernel一致即可复用，请保持二者一致。目前笔者使用环境为ubuntu 24.04.2，kernel为6.12.24-mainline，可复用的`xdma.ko`文件存在于`xdma-ko`文件夹内。


### 上板流程
**注意！以下步骤均在本仓库根目录下运行。**
1. 运行如下命令，使用vivado从jtag烧入NEXST bit流(`system.bit`)。
    ```bash
    make program_fpga BOARD=${BOARD_TYPE} BITSTREAM_PATH=${YOUR_BITSTREAM_PATH}
    # BOARD_TYPE默认值为vcu128，目前支持vcu128/s2c_vu19p
    # BITSTREAM_PATH默认值为./remote/system.bit，可以自定义
    # 烧入失败时可以运行`make list_devices`，检查设备是否被host检测到
    # 每次运行这两个命令会在目录下生成vivado日志文件，请及时清理
    ```
    注意，FPGA重启后第一次烧入bit流需要重启host以实现PCIe设备的重新扫描。完成该步骤后，运行`lspci`可以看到类似如下设备：
    ```bash
    01:00.0 Processing accelerators: Xilinx Corporation Device 9038
    ```
    同时运行`ls /dev/xdma*`可以看到一系列xdma设备。如果不是第一次烧入bit流（即已经检测到PCIe设备，需要更换bit流的情况），在使用vivado完成bit流的烧录后，运行如下命令进行软重新扫描，不需要重启。
    ```bash
    make rescan_pci DEVICE_NUM=${DEVICE_NUM}
    # 本例中，DEVICE_NUM为01:00.0，默认值也是01:00.0
    ```
    
2. 运行如下命令编译上板小工具，在`build`目录下得到`pcie-util`和`load_workload`可执行文件。
    ```bash
    make build_tools
    ```
   如果需要修改工具，xdma驱动的传输API使用方法可以参见`src/workload_test.c`。
3. 运行如下命令加载xdma驱动。
    ```bash
    make load_driver XDMA_KO_PATH=${XDMA_KO_PATH}
    ```
4. 运行如下命令进行FPGA上板。
    ```bash
    make load_and_run ONBOARD_OPTIONS=${OPTIONS} BOOTROM_PATH=${BOOTROM_PATH} WORKLOAD_PATH=${WORKLOAD_PATH}
    # ONBOARD_OPTIONS有--minicom（使用minicom作为串口终端）、--rstsoc（对外设进行reset，仅在有外设时使用）与--bypass（使用xdma bypass通道烧入bin），请根据需要使用，也可以留空。
    # BOOTROM_PATH与WORKLOAD_PATH的默认值为./remote/bootrom.bin与./remote/RV_BOOT.bin。
    ```
    `load_and_run.sh`脚本自动完成软件烧入与终端开启，可以使用`ctrl+\`退出终端。

5. 可以使用`./build/rw_pcie_dram`，通过xdma驱动进行fpga dram的文件读写，详见[host和fpga通过xdma交换文件](https://aul8ejtumo.feishu.cn/wiki/MqEywZPkUiMMFVkrqTJcmlX2nve?from=from_copylink)。使用时可能需要注意核与dram之间的一致性问题。
