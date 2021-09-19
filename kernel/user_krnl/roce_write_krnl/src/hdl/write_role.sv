// This is a generated file. Use and modify at your own risk.
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
module write_role #(
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

assign ap_done = ap_done_n;

// Ready Logic (non-pipelined case)
assign ap_ready = ap_done;


// read logic
localparam TIMER_1S = 250000000; //1s
reg [31:0] cnt;
reg ap_done_n;

assign m_axis_tx_data_tvalid = 1'b0;
assign m_axis_tx_data_tdata  = '0;
assign m_axis_tx_data_tkeep  = '0;
assign m_axis_tx_data_tlast  = '0;

assign m_axis_tx_meta_tlast  = '1;
assign m_axis_tx_meta_tkeep  = '1;

assign s_axis_tx_status_tready = 1'b1;

// done logic, run 5 seconds
always @(posedge ap_clk) begin
  if (areset) begin
    cnt <= '0;
    ap_done_n <= 1'b0;
  end
  else begin
    ap_done_n <= 1'b0;
    if (cnt == TIMER_1S * 5) begin
      ap_done_n <= 1'b1;
      cnt <= '0;
    end else if (ap_start) begin
      cnt <= cnt + 1'b1;
    end
  end
end

reg [31:0] meta_cnt;
reg [47:0] offset;
reg [3:0] state;
localparam IDLE_STATE = 0;
localparam WRITE_META = 1;
localparam WAIT_READY = 2;
reg [C_M_AXIS_TX_META_TDATA_WIDTH-1:0] tx_meta_tdata;
reg tx_meta_tvalid;
assign m_axis_tx_meta_tdata = tx_meta_tdata;
assign m_axis_tx_meta_tvalid = tx_meta_tvalid;

always @(posedge ap_clk) begin
  if (areset|ap_start_pulse) begin
    tx_meta_tdata <= '0;
    tx_meta_tvalid <= '0;
    offset <= '0;
    state <= WRITE_META;
    meta_cnt <= '0;
  end
  else if (ap_start) begin
    case (state)
      WRITE_META: begin
        if (meta_cnt == 1 << debug[31:29]) begin
          // send 2^debug[31:29] metas (1-128)
          state                       <= IDLE_STATE;
        end else begin
          tx_meta_tdata[2:0]     <= 3'b001; // RDMA WRITE
          tx_meta_tdata[26:3]    <= debug[23:0]; // lQPN: TODO: currently use debug[23:0] as lQPN
          tx_meta_tdata[74:27]   <= offset;//lAddr[47:0];
          tx_meta_tdata[122:75]  <= offset;//rAddr[47:0];
          tx_meta_tdata[154:123] <= 1 << debug[28:24]; // len: use 2^debug[28:24] as len (<=2^31)
          tx_meta_tvalid         <= 1'b1;
          state                         <= WAIT_READY;
        end
      end
      WAIT_READY: begin
        if (m_axis_tx_meta_tvalid && m_axis_tx_meta_tready) begin
          tx_meta_tvalid       <= 1'b0;
          state                       <= WRITE_META;
	  meta_cnt              <= meta_cnt + 1'b1;
	  if ((offset + (2 << debug[28:24])) > 48'h000000400000 ) begin
	    // 0x 0040 0000 = 4M Bytes, avoid address overflow??
	    offset                      <= '0;
	  end else begin
	    offset                      <= offset + (1 << debug[28:24]);
          end
        end
      end
      IDLE_STATE: begin
	if (ap_start) begin
          state <= WRITE_META;
	end else begin
          state <= IDLE_STATE;
	end
      end
      default: begin
	if (ap_start) begin
          state <= WRITE_META;
	end else begin
          state <= IDLE_STATE;
	end
      end
    endcase
  end
end

//ila_roce_read inst_ila_roce_read (
//    .clk(ap_clk),
//    .probe0(tx_meta_tdata),//256
//    .probe1(tx_meta_tvalid),
//    .probe2(m_axis_tx_meta_tready),
//    .probe3(m_axis_tx_meta_tkeep),//256/8
//    .probe4(m_axis_tx_meta_tlast),
//    .probe5(state),//4
//    .probe6(offset),//48
//    .probe7(debug),//32
//    .probe8(cnt)//32
//);

endmodule : write_role
`default_nettype wire
