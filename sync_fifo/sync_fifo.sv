module sync_fifo #(parameter DATA_WIDTH  = 8,
                   parameter FIFO_DEPTH  = 32,
                   parameter FIFO_AF_CNT = 16,
                   parameter INIT_FIFO   = 0)(
input   logic                  clk, 
input   logic                  rst_n,
input   logic [DATA_WIDTH-1:0] data_in,
input   logic                  rd_en,
input   logic                  wr_en,
output  logic [DATA_WIDTH-1:0] data_out,
output  logic                  empty,
output  logic                  afull,
output  logic                  full
);    

//calculate memory addr width based on depth
localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

typedef logic [DATA_WIDTH-1:0] DATA_VEC;

//implement fifo in registers
//DATA_VEC [0:FIFO_DEPTH-1] fifo_data;
logic [DATA_WIDTH-1:0] fifo_data [0:FIFO_DEPTH-1];
//logic [0:FIFO_DEPTH-1] [DATA_WIDTH-1:0] fifo_data;

logic [ADDR_WIDTH-1:0] wr_ptr;
logic [ADDR_WIDTH-1:0] rd_ptr;
logic [ADDR_WIDTH :0]  fill_cnt;
logic [DATA_WIDTH-1:0] data_ram ;

assign full    = (fill_cnt == FIFO_DEPTH);
assign empty   = (fill_cnt == 0);
assign afull   = (fill_cnt == FIFO_AF_CNT);

assign data_out = fifo_data[rd_ptr];


always_ff @ (posedge clk, negedge rst_n)
begin : wr_ptr_update
  if (!rst_n) begin
    wr_ptr <= 0;
  end else if (wr_en) begin
    if (!full)
      wr_ptr <= wr_ptr + 1;
  end
end

always_ff @ (posedge clk, negedge rst_n)
begin : rd_ptr_update
  if (!rst_n) begin
    rd_ptr <= 0;
  end else if (rd_en && !empty) begin
    rd_ptr <= rd_ptr + 1;
  end
end

always_ff @ (posedge clk, negedge rst_n)
begin : write_fifo
  if (!rst_n) begin
    for(int i=0;i<FIFO_DEPTH;i++) begin
      if (INIT_FIFO) begin
        //since this fifo is implemented with registers, we may
        //init the fifo registers with a counter.
        fifo_data[i] <= i;
      end
      else begin
        fifo_data[i] <= '0;
      end
    end
  end 
  else begin
    if (wr_en && !full) fifo_data[wr_ptr] <= data_in;
  end
end

always_ff @ (posedge clk, negedge rst_n)
begin : fill_cnt_update
  if (!rst_n) begin
    if (INIT_FIFO)
      //fifo is filled with a counter
      fill_cnt <= FIFO_DEPTH;
    else
      fill_cnt <= 0;
  // Read but no write.
  end else if ((rd_en) && !(wr_en) && (fill_cnt != 0) || (rd_en && (fill_cnt == FIFO_DEPTH))) begin
    fill_cnt <= fill_cnt - 1;
  // Write but no read.
  end else if ((wr_en) && !(rd_en) && (fill_cnt != FIFO_DEPTH) || (wr_en && (fill_cnt == 0))) begin
    fill_cnt <= fill_cnt + 1;
  end
end 

`ifdef FORMAL
FORMAL_sync_fifo  #(.DATA_WIDTH  (DATA_WIDTH),
                    .FIFO_DEPTH  (FIFO_DEPTH),
                    .FIFO_AF_CNT (FIFO_AF_CNT),
                    .INIT_FIFO   (INIT_FIFO))
FORMAL_sync_fifo_inst(.*);
`endif
   

endmodule
