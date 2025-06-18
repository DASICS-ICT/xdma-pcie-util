# Xilinx XDMA-PCIe utility tool for NEXST
## 简介

本工具从[NEXST](https://github.com/DASICS-ICT/nexst)内抽出整理而成，是用于NEXST生成bit（基于Xilinx xdma ip，使用PCIe与host连接）的FPGA上板测试工具。

## 使用方法

### 环境搭建
1. 搭建基于NEXST的FPGA硬件环境（PCIe/jtag连接FPGA板卡与host），确定PCIe/jtag连接正常。
2. 准备host的软件环境（例如vivado，此处略）。如果host第一次用于本流程上板，请运行如下命令。
   ```bash
   sudo ./scripts/init_xdma_usergroup.sh
   ```
   该脚本建立**xdma**用户组，并设置udev规则，将xdma设备放入用户组内。用户可以运行如下命令将自己加入用户组。
   ```bash
   sudo usermod -aG xdma $USER; newgrp xdma
   ```
   该步骤目的主要是便于fpgabot的用户信息识别，并且仅测试软件时可以不需要root权限完成上板。
3. 在EDA上使用NEXST环境生成用于上板的硬件bit流与配套软件bin，软件bin包含bootrom和workload（如bootloader+Linux Kernel，可以根据测试灵活更换）。可以使用如下命令将所需的软硬件payload从远端EDA拷贝到本工作区的`remote`文件夹。（示例为vcu128情况，使用其他版型/流程请自行修改）
    ```bash
    scp ${USER}@${EDA_HOST}:\
        ${PATH_TO_NEXST}/{nanhu-g/ready_for_download/proto_vcu128/{bootrom.bin,RV_BOOT.bin}, \
        work_farm/hw_plat/target_nanhu-g_proto_vcu128/{debug_nets.ltx,system.bit,system.hdf}}\
        ./remote
    ```
4. 准备xdma驱动的`xdma.ko`文件。使用NEXST工作流编译的xdma驱动位于`${PATH_TO_NEXST}/shell/software/build/xdma_drv/`目录下，只要编译时host使用的kernel和上板时host使用的kernel一致即可复用，请保持二者一致。目前笔者使用环境为ubuntu 24.04.2，kernel为6.12.24-mainline，可复用的`xdma.ko`文件存在于`xdma-ko`文件夹内。


### 上板流程
**注意！以下步骤均在本仓库根目录下运行。**
1. 运行如下命令，使用vivado从jtag烧入NEXST bit流(`system.bit`)。
    ```bash
    vivado -mode batch \
        -source ./scripts/program_fpga.tcl \
        -tclargs ${FPGA_DEVICE_TYPE} ${PATH_TO_YOUR_BITSTREAM_FILE}
    # 对于vcu128开发板，FPGA_DEVICE_TYPE为xcvu37p_0
    # 将命令末行修改成 “-tclargs list_devices” 可以进行当前设备检索
    # 每次运行该命令会在目录下生成vivado日志文件，请及时清理
    ```
    注意，FPGA重启后第一次烧入bit流需要重启host以实现PCIe设备的重新扫描。完成该步骤后，运行`lspci`可以看到类似如下设备：
    ```bash
    01:00.0 Processing accelerators: Xilinx Corporation Device 9038
    ```
    同时运行`ls /dev/xdma*`可以看到一系列xdma设备。如果不是第一次烧入bit流（即已经检测到PCIe设备，需要更换bit流的情况），在使用vivado完成bit流的烧录后，运行如下命令进行软重新扫描，不需要重启。
    ```bash
    sudo ./scripts/rescan_pci.sh ${DEVICE_NUM}
    # 本例中，DEVICE_NUM为01:00.0
    ```
    
2. 运行如下命令编译上板小工具，在`src`目录下得到`pcie-util`和`load_workload`可执行文件。
    ```bash
    make -C src
    ```
   如果需要修改工具，xdma驱动的传输API使用方法可以参见`src/workload_test.c`。
3. 运行如下命令加载xdma驱动。
    ```bash
    sudo insmod ${PATH_TO_YOUR_XDMA_KO}
    ```
4. 运行如下命令进行FPGA上板。
    ```bash
    ./scripts/load_and_run.sh xdma0 ${PATH_TO_"bootrom.bin"} ${PATH_TO_"RV_BOOT.bin"}
    ```
    `load_and_run.sh`脚本自动完成软件烧入与终端开启，可以使用`ctrl+\`退出终端。如果希望使用minicom作为终端进行上板，可以将脚本换成`load_and_run_minicom.sh`，其他不变。
