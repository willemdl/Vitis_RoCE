.PHONY: help

help::
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make all TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86> SYSROOT=<sysroot_path> NET_KRNL=<network_krnl_name> USER_KRNL=<user_krnl_name> USER_KRNL_MODE=<rtl/hls> EXE_NUM=<1/2>"
	$(ECHO) "      Command to generate the design for specified Target and Shell."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH and SYSROOT is required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  make clean "
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""
	$(ECHO) "  make sd_card TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86> SYSROOT=<sysroot_path>"
	$(ECHO) "      Command to prepare sd_card files."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH and SYSROOT is required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  make check TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86> SYSROOT=<sysroot_path>"
	$(ECHO) "      Command to run application in emulation."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH and SYSROOT is required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  make build TARGET=<sw_emu/hw_emu/hw> DEVICE=<FPGA platform> HOST_ARCH=<aarch32/aarch64/x86> SYSROOT=<sysroot_path>"
	$(ECHO) "      Command to build xclbin application."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH and SYSROOT is required for SoC shells"
	$(ECHO) ""

# Points to top directory of Git repository
COMMON_REPO = ./
PWD = $(shell readlink -f .)
ABS_COMMON_REPO = $(shell readlink -f $(COMMON_REPO))

TARGET := hw
HOST_ARCH := x86
SYSROOT :=
DEVICE ?= xilinx_u280_xdma_201920_3
VITIS_PLATFORM := ${DEVICE}

XCLBIN_NAME = network

EXE_NUM ?= 1
USER_KRNL_MODE ?= rtl
NET_KRNL ?= roce
USER_KRNL ?= roce_dummy_krnl
$(info INFO: PARAMETER LIST)
$(info INFO: TARGET is [${TARGET}])
$(info INFO: DEVICE is [${DEVICE}])
$(info INFO: NET_KRNL is [${NET_KRNL}])
$(info INFO: USER_KRNL is [${USER_KRNL}])
$(info INFO: USER_KRNL_MODE is [${USER_KRNL_MODE}])
$(info INFO: EXE_NUM is [${EXE_NUM}])

ifeq ($(NET_KRNL), roce)
  KRNL_1 := rocetest_krnl
else
  KRNL_1 := network_krnl
endif
KRNL_2 := ${USER_KRNL}
KRNL_3 := cmac_krnl

$(info INFO: KERNEL LIST)
$(info INFO: KRNL_1 is [${KRNL_1}])
$(info INFO: KRNL_2 is [${KRNL_2}])
$(info INFO: KRNL_3 is [${KRNL_3}])


include ./utils.mk
POSTSYSLINKTCL ?= $(shell readlink -f ./scripts/post_sys_link.tcl)
CONFIGLINKTCL ?= $(shell readlink -f ./scripts/compile.cfg)

IPREPOPATH ?= ./build/fpga-network-stack/iprepo
$(info INFO: IPREPOPATH is [${IPREPOPATH}])

XSA := $(call device2xsa, $(DEVICE))
TEMP_DIR := ./_x.$(TARGET).$(XSA)
BUILD_DIR := ./build_dir.$(TARGET).$(XSA)

VPP := $(XILINX_VITIS)/bin/v++
SDCARD := sd_card
VITIS_VERSION := $(shell echo $(XILINX_VITIS) | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')
$(info INFO: VITIS_VERSION is [${VITIS_VERSION}])


#Include Libraries
include $(ABS_COMMON_REPO)/common/includes/opencl/opencl.mk
include $(ABS_COMMON_REPO)/common/includes/xcl2/xcl2.mk
CXXFLAGS += $(xcl2_CXXFLAGS)
LDFLAGS += $(xcl2_LDFLAGS)
HOST_SRCS += $(xcl2_SRCS)
include config_$(USER_KRNL_MODE).mk

CXXFLAGS += $(opencl_CXXFLAGS) -Wall -O0 -g -std=gnu++14
CXXFLAGS +=  -DVITIS_PLATFORM=$(VITIS_PLATFORM)
LDFLAGS += $(opencl_LDFLAGS)

ifeq ($(NET_KRNL), roce)
  HOST_SRCS += host/${USER_KRNL}/host$(EXE_NUM).cpp
else
  HOST_SRCS += host/${USER_KRNL}/host.cpp
endif

# Host compiler global settings
CXXFLAGS += -fmessage-length=0
LDFLAGS += -lrt -lstdc++

ifneq ($(HOST_ARCH), x86)
  LDFLAGS += --sysroot=$(SYSROOT)
endif

# Kernel compiler global settings
CLFLAGS += -t $(TARGET) --platform $(DEVICE) --save-temps #--config $(CONFIGLINKTCL)
CLFLAGS += --kernel_frequency 250
CLFLAGS += --user_ip_repo_paths $(IPREPOPATH)
ifneq ($(TARGET), hw)
  CLFLAGS += -g
endif

# Linker params
# Linker userPostSysLinkTcl param
$(info INFO: $$POSTSYSLINKTCL is [${POSTSYSLINKTCL}])
CLFLAGS += --advanced.param compiler.userPostSysLinkOverlayTcl=$(POSTSYSLINKTCL) #--xp param:compiler.userPostSysLinkTcl=$(POSTSYSLINKTCL)
#CLFLAGS += --dk chipscope:network_krnl_1:m_axis_tcp_open_status --dk chipscope:network_krnl_1:s_axis_tcp_tx_meta --dk chipscope:network_krnl_1:s_axis_tcp_open_connection
CLFLAGS += --config ./kernel/user_krnl/${USER_KRNL}/config_sp_${USER_KRNL}.txt
# CLFLAGS += --profile_kernel stall:${USER_KRNL}:all:all
#endif

#ifeq ($(VITIS_VERSION), 2020.2)
#  CLFLAGS += --vivado.impl.strategies "Performance_Explore,Area_Explore"
#  # CLFLAGS += --vivado.impl.strategies "All"
#else
#  CLFLAGS += --vivado.prop run.impl_1.STEPS.PHYS_OPT_DESIGN.IS_ENABLED=true
#  CLFLAGS += --vivado.prop run.impl_1.STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE=Explore
#endif

# LDCLFLAGS += --kernel_frequency "0:250|1:250"
# LDCLFLAGS += --profile_kernel stall:${USER_KRNL}:all:all

ifeq ($(NET_KRNL), roce)
  EXECUTABLE = ./host/host$(EXE_NUM)
else
  EXECUTABLE = ./host/host
endif

CMD_ARGS = $(BUILD_DIR)/${XCLBIN_NAME}.xclbin
EMCONFIG_DIR = $(TEMP_DIR)
EMU_DIR = $(SDCARD)/data/emulation

BINARY_CONTAINERS += $(BUILD_DIR)/${XCLBIN_NAME}.xclbin
BINARY_CONTAINER_OBJS += $(TEMP_DIR)/${KRNL_1}.xo $(TEMP_DIR)/${KRNL_2}.xo $(TEMP_DIR)/${KRNL_3}.xo 

CP = cp -rf

.PHONY: all clean cleanall docs emconfig
all: check-devices $(EXECUTABLE) $(BINARY_CONTAINERS) emconfig sd_card

.PHONY: exe
exe: $(EXECUTABLE)

.PHONY: build
build: $(BINARY_CONTAINERS)
export IPREPOPATH
# Building kernel
$(BUILD_DIR)/${XCLBIN_NAME}.xclbin: $(BINARY_CONTAINER_OBJS)
	mkdir -p $(BUILD_DIR)
	$(VPP) $(CLFLAGS) --temp_dir $(BUILD_DIR) -l $(LDCLFLAGS) -o'$@' $(+)

# Building Host
.PHONY: compile
compile: $(EXECUTABLE)
$(EXECUTABLE): check-xrt $(HOST_SRCS) $(HOST_HDRS)
	$(CXX) $(CXXFLAGS) $(HOST_SRCS) $(HOST_HDRS) -o '$@' $(LDFLAGS)

emconfig:$(EMCONFIG_DIR)/emconfig.json
$(EMCONFIG_DIR)/emconfig.json:
	emconfigutil --platform $(DEVICE) --od $(EMCONFIG_DIR)

check: all
ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
ifeq ($(HOST_ARCH), x86)
	$(CP) $(EMCONFIG_DIR)/emconfig.json .
	XCL_EMULATION_MODE=$(TARGET) ./$(EXECUTABLE) $(BUILD_DIR)/${XCLBIN_NAME}.xclbin
else
	mkdir -p $(EMU_DIR)
	$(CP) $(XILINX_VITIS)/data/emulation/unified $(EMU_DIR)
	mkfatimg $(SDCARD) $(SDCARD).img 500000
	launch_emulator -no-reboot -runtime ocl -t $(TARGET) -sd-card-image $(SDCARD).img -device-family $(DEV_FAM)
endif
else
ifeq ($(HOST_ARCH), x86)
	./$(EXECUTABLE) $(BUILD_DIR)/${XCLBIN_NAME}.xclbin
endif
endif
ifneq ($(TARGET),$(findstring $(TARGET), hw hw_emu))
$(warning WARNING:Application supports only hw hw_emu TARGET. Please use the target for running the application)
endif


ifeq ($(HOST_ARCH), x86)
	perf_analyze profile -i profile_summary.csv -f html
endif

sd_card: $(EXECUTABLE) $(BINARY_CONTAINERS) emconfig
ifneq ($(HOST_ARCH), x86)
	mkdir -p $(SDCARD)/$(BUILD_DIR)
	$(CP) $(B_NAME)/sw/$(XSA)/boot/generic.readme $(B_NAME)/sw/$(XSA)/xrt/image/* xrt.ini $(EXECUTABLE) $(SDCARD)
	$(CP) $(BUILD_DIR)/*.xclbin $(SDCARD)/$(BUILD_DIR)/
ifeq ($(TARGET),$(filter $(TARGET),sw_emu hw_emu))
	$(ECHO) 'cd /mnt/' >> $(SDCARD)/init.sh
	$(ECHO) 'export XILINX_VITIS=$$PWD' >> $(SDCARD)/init.sh
	$(ECHO) 'export XCL_EMULATION_MODE=$(TARGET)' >> $(SDCARD)/init.sh
	$(ECHO) './$(EXECUTABLE) $(CMD_ARGS)' >> $(SDCARD)/init.sh
	$(ECHO) 'reboot' >> $(SDCARD)/init.sh
else
	[ -f $(SDCARD)/BOOT.BIN ] && echo "INFO: BOOT.BIN already exists" || $(CP) $(BUILD_DIR)/sd_card/BOOT.BIN $(SDCARD)/
	$(ECHO) './$(EXECUTABLE) $(CMD_ARGS)' >> $(SDCARD)/init.sh
endif
endif

# Cleaning stuff
clean:
	-$(RMDIR) $(EXECUTABLE) $(XCLBIN)/{*sw_emu*,*hw_emu*} 
	-$(RMDIR) profile_* TempConfig system_estimate.xtxt *.rpt *.csv .run
	-$(RMDIR) src/*.ll *v++* .Xil emconfig.json dltmp* xmltmp* *.log *.jou *.wcfg *.wdb

cleanall: clean
	-$(RMDIR) build_dir* sd_card*
	-$(RMDIR) _x.* *xclbin.run_summary qemu-memory-_* emulation/ _vimage/ pl* start_simulation.sh *.xclbin
	-$(RMDIR) ./tmp_kernel_pack* ./packaged_kernel* 


