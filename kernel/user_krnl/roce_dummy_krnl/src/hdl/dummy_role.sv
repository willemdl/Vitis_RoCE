// This is a generated file. Use and modify at your own risk.
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
module dummy_role #(
  parameter integer C_M_AXIS_TX_META_TDATA_WIDTH   = 256,
  parameter integer C_M_AXIS_TX_DATA_TDATA_WIDTH   = 512,
  parameter integer C_S_AXIS_TX_STATUS_TDATA_WIDTH = 512
)
(
  // System Signals
  input  wire                                        ap_clk                 ,
  input  wire                                        ap_rst_n               ,
  // Pipe (AXI4-Stream host) interface m_axis_tx_meta
  output wire                                        m_axis_tx_meta_tvalid  ,
  input  wire                                        m_axis_tx_meta_tready  ,
  output wire [C_M_AXIS_TX_META_TDATA_WIDTH-1:0]     m_axis_tx_meta_tdata   ,
  output wire [C_M_AXIS_TX_META_TDATA_WIDTH/8-1:0]   m_axis_tx_meta_tkeep   ,
  output wire                                        m_axis_tx_meta_tlast   ,
  // Pipe (AXI4-Stream host) interface m_axis_tx_data
  output wire                                        m_axis_tx_data_tvalid  ,
  input  wire                                        m_axis_tx_data_tready  ,
  output wire [C_M_AXIS_TX_DATA_TDATA_WIDTH-1:0]     m_axis_tx_data_tdata   ,
  output wire [C_M_AXIS_TX_DATA_TDATA_WIDTH/8-1:0]   m_axis_tx_data_tkeep   ,
  output wire                                        m_axis_tx_data_tlast   ,
  // Pipe (AXI4-Stream host) interface s_axis_tx_status
  input  wire                                        s_axis_tx_status_tvalid,
  output wire                                        s_axis_tx_status_tready,
  input  wire [C_S_AXIS_TX_STATUS_TDATA_WIDTH-1:0]   s_axis_tx_status_tdata ,
  input  wire [C_S_AXIS_TX_STATUS_TDATA_WIDTH/8-1:0] s_axis_tx_status_tkeep ,
  input  wire                                        s_axis_tx_status_tlast ,
  // Control Signals
  input  wire                                        ap_start               ,
  output wire                                        ap_idle                ,
  output wire                                        ap_done                ,
  output wire                                        ap_ready               ,
  input  wire [32-1:0]                               debug                  
);


timeunit 1ps;
timeprecision 1ps;

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
// Large enough for interesting traffic.
localparam integer  LP_DEFAULT_LENGTH_IN_BYTES = 16384;
localparam integer  LP_NUM_EXAMPLES    = 1;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* KEEP = "yes" *)
logic                                areset                         = 1'b0;
logic                                ap_start_r                     = 1'b0;
logic                                ap_idle_r                      = 1'b1;
logic                                ap_start_pulse                ;
logic [LP_NUM_EXAMPLES-1:0]          ap_done_i                     ;
logic [LP_NUM_EXAMPLES-1:0]          ap_done_r                      = {LP_NUM_EXAMPLES{1'b0}};
logic [32-1:0]                       ctrl_xfer_size_in_bytes        = LP_DEFAULT_LENGTH_IN_BYTES;
logic [32-1:0]                       ctrl_constant                  = 32'd1;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

// create pulse when ap_start transitions to 1
always @(posedge ap_clk) begin
  begin
    ap_start_r <= ap_start;
  end
end

assign ap_start_pulse = ap_start & ~ap_start_r;

// ap_idle is asserted when done is asserted, it is de-asserted when ap_start_pulse
// is asserted
always @(posedge ap_clk) begin
  if (areset) begin
    ap_idle_r <= 1'b1;
  end
  else begin
    ap_idle_r <= ap_done ? 1'b1 :
      ap_start_pulse ? 1'b0 : ap_idle;
  end
end

assign ap_idle = ap_idle_r;

// Done logic
always @(posedge ap_clk) begin
  if (areset) begin
    ap_done_r <= '0;
  end
  else begin
    ap_done_r <= (ap_done) ? '0 : ap_done_r | ap_done_i;
  end
end

assign ap_done = &ap_done_r;

// Ready Logic (non-pipelined case)
assign ap_ready = ap_done;


// dummy logic
localparam WAIT_TIMER = 250000000;
reg [31:0] cnt;
assign m_axis_tx_meta_tvalid = 1'b0;
assign m_axis_tx_meta_tdata  = '0;
assign m_axis_tx_meta_tkeep  = '0;
assign m_axis_tx_meta_tlast  = '0;

assign m_axis_tx_data_tvalid = 1'b0;
assign m_axis_tx_data_tdata  = '0;
assign m_axis_tx_data_tkeep  = '0;
assign m_axis_tx_data_tlast  = '0;

assign s_axis_tx_status_tready = 1'b1;

always @(posedge ap_clk) begin
  if (areset) begin
    cnt <= '0;
  end
  else begin
    cnt <= cnt + 1;
    if (cnt == WAIT_TIMER) begin
      ap_done_i[0] <= 1'b1;
      cnt <= '0;
    end
  end
end


endmodule : dummy_role
`default_nettype wire
