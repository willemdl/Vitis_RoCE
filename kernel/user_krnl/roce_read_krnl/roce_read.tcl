
# ila
create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_roce_read
set_property -dict [list CONFIG.C_NUM_OF_PROBES {9} CONFIG.C_PROBE0_WIDTH {256} \
CONFIG.C_PROBE3_WIDTH {32} CONFIG.C_PROBE5_WIDTH {4} CONFIG.C_PROBE6_WIDTH {48} \
CONFIG.C_PROBE7_WIDTH {32} CONFIG.C_PROBE8_WIDTH {32} \
CONFIG.C_EN_STRG_QUAL {1} CONFIG.C_ADV_TRIGGER {true} \
CONFIG.C_INPUT_PIPE_STAGES {1}] [get_ips ila_roce_read]
update_compile_order -fileset sources_1
