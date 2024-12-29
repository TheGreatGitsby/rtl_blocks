
//This is an asymmetric fifo with the following assumptions:
// 1 - If any input streams are valid, ALL inputfifos are written to.
//     The validfifo is used to keep track of which inputfifo
//     has valid data.
  
 module Nto1_sync_fifo #(N = 4, DATA_WIDTH = 8, DEPTH = 8)
         (input logic clk_i,
          input logic rst_n_i,
          input logic [0 : N-1] [DATA_WIDTH-1:0] data_i,
          input logic [0: N-1] wr_en_i,
          input logic rd_en_i,
          output logic                   fifo_full_o,
          output logic                   fifo_empty_o,
          output logic [DATA_WIDTH-1:0]  data_o
         );

//one signal reads all input/valid fifos at once
logic            fifo_rd_en;

logic [N-1:0] [DATA_WIDTH-1:0] infifo_data;

logic     outfifo_wr_en;
logic     outfifo_full;

logic [N-1:0] validfifo_data;
logic         validfifo_empty;

logic [$clog2(N+1)-1:0] fifo_sel;
logic [$clog2(N+1)-1:0] fifo_sel_reg;

generate
  for (genvar i=0; i<N; i++) begin
    sync_fifo #(
      .DATA_WIDTH  (DATA_WIDTH),
      .FIFO_DEPTH  (DEPTH), 
      .FIFO_AF_CNT (DEPTH-1), 
      .INIT_FIFO   (0))
    input_fifo (
      .clk       (clk_i), 
      .rst_n     (rst_n_i),
      .data_in   (data_i[i]),
      .rd_en     (fifo_rd_en),
      .wr_en     (|wr_en_i), //always write if any are valid
      .data_out  (infifo_data[i]),
      .empty     (),
      .afull     (),
      .full      ()
    );
  end
endgenerate

//This fifo keeps track of which entries are valid
    sync_fifo #(
      .DATA_WIDTH  (N),
      .FIFO_DEPTH  (DEPTH), 
      .FIFO_AF_CNT (DEPTH-1), 
      .INIT_FIFO   (0))
    valid_fifo (
      .clk       (clk_i), 
      .rst_n     (rst_n_i),
      .data_in   (wr_en_i),
      .rd_en     (fifo_rd_en),
      .wr_en     (|wr_en_i), //always write if any are valid
      .data_out  (validfifo_data),
      .empty     (validfifo_empty),
      .afull     (),
      .full      (fifo_full_o)
    );

logic valid_found; //used to detect multiple set bits in validfifo output

// Move data from the input fifos into the output fifo
always_comb
begin

  //defaults
  fifo_rd_en      <= 0;
  outfifo_wr_en   <= 0;
  valid_found      = 0; //blocking to detect multiple set bits
  fifo_sel        <= fifo_sel_reg;

  if (!validfifo_empty && !outfifo_full) begin
    //assume this is the last valid entry in the fifo
    fifo_rd_en      <= 1;
    fifo_sel        <= 0;
    fifo_rd_en      <= 1;

    for (int i=N-1; i>=0; i--) begin
      //loop from high to low to give priority to closest index to
      //the current fifo_sel.
      if (i>=fifo_sel_reg) begin
        if (validfifo_data[i]) begin
          //There is a valid entry in the infifo's that needs to
          //be written to the out fifo.
          outfifo_wr_en   <= 1;
          if (valid_found) begin
            //This is at least the second set bit, so dont pop the
            //fifo entries yet.
            fifo_rd_en   <= 0;
            fifo_sel     <= i;
          end
          else begin
            //first validfifo bit set found.
            valid_found = 1;
            fifo_sel   <= i;
          end
        end
      end
    end
  end
end

always_ff @(posedge clk_i) begin
  if (!rst_n_i) begin
    fifo_sel_reg <= 0;
  end
  else begin
    if (outfifo_wr_en) begin
      //inputfifo entry is transferred to output fifo
      if (fifo_rd_en) begin
        //this was the last valid entry, reset sel to 0
        fifo_sel_reg <= 0;
      end
      else begin
        //set reg for the next entry as a starting point.
        fifo_sel_reg <= fifo_sel+1;
      end
    end
  end
end

//This just frees up input fifo space, particularly useful in sparse
//inputs where not all inputs are valid.
    sync_fifo #(
      .DATA_WIDTH (DATA_WIDTH),
      .FIFO_DEPTH (DEPTH/2), //arbitrary
      .INIT_FIFO  (0))
    output_fifo (
      .clk       (clk_i), 
      .rst_n     (rst_n_i),
      .data_in   (infifo_data[fifo_sel]),
      .rd_en     (rd_en_i),
      .wr_en     (outfifo_wr_en),
      .data_out  (data_o),
      .empty     (fifo_empty_o),
      .full      (outfifo_full)
    );

`ifdef FORMAL
FORMAL_Nto1_sync_fifo #(.N          (N),
                        .DATA_WIDTH (DATA_WIDTH),
                        .DEPTH      (DEPTH))
FORMAL_Nto1_sync_fifo_inst(.*);
`endif

endmodule




