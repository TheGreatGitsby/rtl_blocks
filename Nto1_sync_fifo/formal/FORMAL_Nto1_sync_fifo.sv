
module FORMAL_Nto1_sync_fifo #(parameter N          = 4,
                               parameter DATA_WIDTH = 8,
                               parameter DEPTH      = 32)
         (input logic clk_i,
          input logic rst_n_i,
          input logic [0 : N-1] [DATA_WIDTH-1:0] data_i,
          input logic [0: N-1] wr_en_i,
          input logic rd_en_i,
          input logic                   fifo_full_o,
          input logic                   fifo_empty_o,  //TODO
          input logic [DATA_WIDTH-1:0]  data_o
         );

//model the fifo fill level
logic [$clog2(DEPTH)-1:0] fill_cnt;
always_ff @ (posedge clk_i)
begin : fill_cnt_update
  if (!rst_n_i) begin
      fill_cnt <= 0;
  end 
  else begin
    for (int i=0; i<N; i++) begin
      // Write
      if ((wr_en_i[i]) && (!fifo_full_o)) begin
        fill_cnt = fill_cnt + 1;
        if ((data_i[i] == ndc_data) && !checking) begin
          fill_check <= (rd_en_i && !fifo_empty_o) ? fill_cnt-1 : fill_cnt;
        end
      end
    end
    //Read
    if ((rd_en_i) && (!fifo_empty_o)) begin
      fill_cnt = fill_cnt - 1;
    end
  end
end 

//capture the fill level at the time of free variable detection
//(* anyconst *) logic [DATA_WIDTH-1:0] ndc_data;
logic [DATA_WIDTH-1:0] ndc_data;
logic checking;
logic [$clog2(DEPTH*N)-1:0] fill_check;
logic [$clog2(DEPTH*N)-1:0] fill_countdown;

always_ff @ (posedge clk_i)
begin : capture_fill_cnt
  if (!rst_n_i) begin
    checking        <= 0;
    fill_countdown  <= 0;
  end
  else begin
    for (int i=0; i<N; i++) begin
      if ((data_i[i] == ndc_data) && wr_en_i[i] && !checking && !fifo_full_o) begin
        checking   <= 1;
      end
    end
    if (checking && rd_en_i) begin
      if (fill_countdown == 32'h1) begin 
        checking   <= 0;
        assert (data_o == ndc_data);
      end
      else  begin
        fill_countdown <= fill_countdown-1;
      end
    end
  end
end

initial assume(!rst_n_i);

always_ff @ (posedge clk_i) begin
  assume($stable(ndc_data));
end

endmodule
