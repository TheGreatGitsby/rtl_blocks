module sync_fifo_NtoM #(parameter DATA_WIDTH  = 8,
                        parameter FIFO_DEPTH  = 32,
                        parameter FIFO_AF_CNT = 16,
                        parameter N           = 1,
                        parameter M           = 1,
                        parameter INIT_FIFO   = 0)(
input   logic                  clk, 
input   logic                  rst_n,
input   logic [0:N-1] [DATA_WIDTH-1:0] data_in,
input   logic [$clog2(N)-1:0] wr_en,
output  logic [0:M-1] [DATA_WIDTH-1:0] data_out,
input   logic [$clog2(M)-1:0] rd_en,
output  logic [$clog2(M)-1:0]  words_avail, //(empty) a number between 0 and M entries 
                                            //        valid to read this cycle
output  logic                  afull,
output  logic                  empty_slots_avail //(full)  a number between 0 and N entries 
                                                 //        available to write this cycle
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
logic [ADDR_WIDTH :0]  avail_slots;

logic avail_slots = FIFO_DEPTH - fill_cnt;

assign full    = (fill_cnt == FIFO_DEPTH);
assign afull   = (fill_cnt == FIFO_AF_CNT);

always_comb begin
  for (int i=0; i<M; i++) begin
    data_out[i] = fifo_data[rd_ptr+i];
    empty[i]    = (fill_cnt <= i);
  end
end

assign words_avail  = (fill_cnt < M) ? fill_cnt : M;

always_ff @ (posedge clk, negedge rst_n)
begin : wr_ptr_update
  if (!rst_n) begin
    wr_ptr <= 0;
  end else if (wr_en>0) begin
    wr_ptr <= (wr_en > avail_slots) rd_ptr : wr_ptr + wr_en;
  end
end

always_ff @ (posedge clk, negedge rst_n)
begin : rd_ptr_update
  if (!rst_n) begin
    rd_ptr <= 0;
  end else begin
    rd_ptr <= (rd_en < fill_cnt) ? rd_ptr + rd_en :
                                   rd_ptr + fill_cnt;
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
    for (int i=0; i<N; i++) begin
      if ((wr_en < i) && (i < avail_slots)) begin
        fifo_data[wr_ptr+i] = data_in[i];
      end
    end
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
  end else if (wr_en > rd_en) begin
    fill_cnt <= ((wr_en - rd_en) > (FIFO_DEPTH - fill_cnt)) ? 
                                      fill_cnt <= FIFO_DEPTH : 
                                      (wr_en - rd_en) + fill_cnt;
  end else if (rd_en > wr_en) begin
    fill_cnt <= ((rd_en - wr_en) > fill_cnt) ? 0 :
                                      fill_cnt - (rd_en - wr_en);
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
