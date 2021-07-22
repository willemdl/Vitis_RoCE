VIVADO := $(XILINX_VIVADO)/bin/vivado
$(TEMP_DIR)/${KRNL_1}.xo: kernel/rocetest_krnl/kernel.xml kernel/rocetest_krnl/package_network_krnl.tcl scripts/gen_xo.tcl kernel/rocetest_krnl/src/hdl/*.sv kernel/rocetest_krnl/src/hdl/*.v
	mkdir -p $(TEMP_DIR)
	$(VIVADO) -mode batch -source scripts/gen_xo.tcl -tclargs $(TEMP_DIR)/${KRNL_1}.xo roce_host $(TARGET) $(DEVICE) $(XSA) kernel/rocetest_krnl/kernel.xml kernel/rocetest_krnl/package_network_krnl.tcl

$(TEMP_DIR)/${KRNL_3}.xo: kernel/cmac_krnl/cmac_krnl.xml kernel/cmac_krnl/package_cmac_krnl.tcl scripts/gen_xo.tcl kernel/cmac_krnl/src/hdl/*.sv
	mkdir -p $(TEMP_DIR)
	$(VIVADO) -mode batch -source scripts/gen_xo.tcl -tclargs $(TEMP_DIR)/${KRNL_3}.xo ${KRNL_3} $(TARGET) $(DEVICE) $(XSA) kernel/cmac_krnl/cmac_krnl.xml kernel/cmac_krnl/package_cmac_krnl.tcl
