# Vitis with 100 Gbps RoCE v2 Network Stack

This repository provides RoCE v2 network support at 100 Gbps in Vitis.
Simple benchmark examples are provided to demonstrate the usage.

We use the [Vitis_with_100Gbps_TCP-IP](https://github.com/fpgasystems/Vitis_with_100Gbps_TCP-IP) as our starting point. This project should fully compatable with the TCP/IP stack. The folder fpga-network-stack/ is replaced by submodule [fpga-netwrok-stack](https://github.com/hcxxstl/fpga-network-stack), which is forked from the [original one](https://github.com/fpgasystems/fpga-network-stack) by ETHz systems group.

## Architecture Overview

The same architecture as the TCP/IP project is used with three Vitis kernels: `CMAC` kernel, `RoCE` kernel and `User` kernel. Several `User` kernels are provided

The top level structure can be seen [here](img/top.pdf).

### CMAC kernel
The `CMAC` kernel remains the same as in [Vitis_with_100Gbps_TCP-IP](https://github.com/fpgasystems/Vitis_with_100Gbps_TCP-IP).

### RoCE Kernel
Since we applied the RoCE as the networking stack, the `network` kenrel is repalced by our `RoCE` kernel. It includes serveral HLS IPs from [fpga-netwrok-stack](https://github.com/hcxxstl/fpga-network-stack). This kernel works in the sequential mode and at 250 MHz.
The [interface](img/roce_inf.pdf) can be found in the img/ directory.

More detials are comming in the future...

### User Kernel
The User kernel is the kernel where user-defined applications are. It is the upper stream kernel that issues RDMA commands to the RoCE kernel. It can be designed for any application that needs RDMA networking. The required interface of the User kernel is shown [here](fig/user_inf.pdf). This kernel also works in sequential execution mode as it should be triggered by the host program. It is clocked at 250 MHz in order to coordinate with the RoCE kernel.

<!-- ## User-Network Kernel Interface -->



## Performance Benchmark
We did simple RDMA READ operation benchmarks to evaluate this RoCE stack. The [throughput](img/read_th.eps) and [latency](img/read_la.eps) results can be seen in the [img/](img/) folder.

## Clone the Repository

Git Clone 

	git clone	
	git submodule update --init --recursive

## Package HLS IPs for the Stack

Setup the network stack HLS IPs:

    mkdir build
    cd build
    cmake .. -DFDEV_NAME=u280
    make installip


## Create Design

The following example command will synthesis and implement the design with selected `User` kernel. The generated XCLBIN resides in folder `build_dir.hw.xilinx_*`. The generated host executable resides in folder `host`.

    cd ../
    make all DEVICE=/opt/xilinx/platforms/xilinx_u280_xdma_201920_3/xilinx_u280_xdma_201920_3.xpfm USER_KRNL=roce_read_krnl EXE_NUM=0

Explaination for the arguments are as follows. Default values can be found in [Makefile](Makefile).

* `DEVICE` Alveo development target platform
* `TARGET` Build targets defined by Vitis
* `USER_KRNL` Name of the user kernel
* `NET_KRNL` Either roce or tcp
* `USER_KRNL_MODE` If the user kernel is a rtl kernel, rtl mode should be specified. If the user kernel is a C/C++ kernel, then hls mode should be specified.
* `EXE_NUM` Either 0 or 1. Parameters required to establish an RDMA connection for two endpoints are set in 2 different host codes.
* `IPREPOPATH` The location of your packaged IPs

onnection established with that port. Usage: ./host XCLBIN_FILE  [#RxByte] [Port]                     |

## Repository structure

~~~
├── fpga-network-stack
├── scripts
├── kernel
│   └── cmac_krnl
│   └── network_krnl
│   └── rocetest_krnl
│   └── user_krnl
|		└── iperf_krnl
|		└── scatter_krnl
|		└── hls_send_krnl
|		└── hls_recv_krnl
|		└── roce_read_krnl
|		└── roce_write_krnl
|		└── hls_dummy_krnl
├── host
|	└── iperf_krnl
|	└── scatter_krnl
|	└── hls_send_krnl
|	└── hls_recv_krnl
|	└── roce_read_krnl
|	└── roce_write_krnl
|	└── hls_dummy_krnl
├── common
├── img
~~~

* fpga-network-stack: this folder contains the HLS code for 100 Gbps TCP/IP stack
* scripts: this folder contains scripts to pack each kernel and to connect cmac kernel with GT pins
* kernel: this folder contains the rtl/hls code of cmac kernel, network kernel and user kernel. User kernel can be configured to one of the example kernels 
* host: this folder contains the host code of each user kernel
* img: this folder contains images 
* common: this folder contains neccessary libraries for running the vitis kernel


## Support

### Tools
To package HLS IPs, use 2020.1.

| Vitis  | XRT       |
|--------|-----------|
| 2020.2 | 2.9.317   |

### Alveo Cards

| Alveo | Development Target Platform(s) | 
|-------|----------|
| U280  | xilinx_u280_xdma_201920_3 | 
| U250  | xilinx_u250_gen3x16_xdma_202020_1 | 

We use the HBM on U280 and host memory on U250 as the memory block for RDMA. To switch to another FPGA, the configurations should be modified manully. For example, change the `HBM[0]` to `HOST[0]` [here](kernel/user_krnl/roce_read_krnl/config_sp_roce_read_krnl.txt) for the read kernel.

### Requirements

In order to generate this design you will need a valid [UltraScale+ Integrated 100G Ethernet Subsystem](https://www.xilinx.com/products/intellectual-property/cmac_usplus.html) license set up in Vivado.

## Acknowledgement
I would like to thank
* David Sidler for developing the InfiniBand RC transport service and RoCE v2 IPs in HLS
* Zhenhao He for the TCP/IP stack design and his help
* Mario Daniel Ruiz Noguera for sharing his knowledge on Xilinx FPGAs and Vitis tool
* Xilinx for providing the Xilinx Adaptive Compute Cluster
* Zaid Al-Ars for offering me this challenging project and guiding me through the journey

