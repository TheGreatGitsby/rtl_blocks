
module FORMAL_sync_fifo #(parameter DATA_WIDTH  = 8,
                          parameter FIFO_DEPTH  = 32,
                          parameter FIFO_AF_CNT = 16,
                          parameter INIT_FIFO   = 0)(
input   logic                  clk, 
input   logic                  rst_n,
input   logic [DATA_WIDTH-1:0] data_in,
input   logic                  rd_en,
input   logic                  wr_en,
input   logic [DATA_WIDTH-1:0] data_out,
input   logic                  empty,
input   logic                  afull,
input   logic                  full
);    

//model the fifo fill level
logic [$clog2(FIFO_DEPTH)-1:0] fill_cnt;
always_ff @ (posedge clk)
begin : fill_cnt_update
  if (!rst_n) begin
    if (INIT_FIFO)
      //fifo is filled with a counter
      fill_cnt <= FIFO_DEPTH;
    else
      fill_cnt <= 0;
  // Read but no write.
  end else if ((rd_en) && !(wr_en) && (!empty) || (rd_en && (full))) begin
    fill_cnt <= fill_cnt - 1;
  // Write but no read.
  end else if ((wr_en) && !(rd_en) && (!full) || (wr_en && empty)) begin
    fill_cnt <= fill_cnt + 1;
  end
end 

//capture the fill level at the time of free variable detection
//(* anyconst *) logic [DATA_WIDTH-1:0] ndc_data;
logic [DATA_WIDTH-1:0] ndc_data;
//logic [DATA_WIDTH-1:0] ndc_data;
logic checking;
logic [$clog2(FIFO_DEPTH)-1:0] fill_check;

always_ff @ (posedge clk)
begin : capture_fill_cnt
  if (!rst_n) begin
    checking    <= 0;
  end
  else begin
    if ((data_in == ndc_data) && wr_en && !checking && !full) begin
      fill_check <= (rd_en && !empty) ? fill_cnt : fill_cnt+1;
      checking   <= 1;
    end
    if (checking && rd_en) begin
      if (fill_check == 32'h1) begin 
        checking   <= 0;
        assert (data_out == ndc_data);
      end
      else  begin
        fill_check <= fill_check-1;
      end
    end
  end
end

initial assume(!rst_n);

always_ff @ (posedge clk) begin
  assume($stable(ndc_data));
end


endmodule
