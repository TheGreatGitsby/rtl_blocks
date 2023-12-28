formal: ./verilog/FORMAL_Nto1_sync_fifo.v ./verilog/Nto1_sync_fifo.v ../../sync_fifo/sync_fifo.sv ../../sync_fifo/formal/FORMAL_sync_fifo.sv
	sby Nto1_sync_fifo.sby -f

./verilog/FORMAL_Nto1_sync_fifo.v: FORMAL_Nto1_sync_fifo.sv
	sv2v FORMAL_Nto1_sync_fifo.sv > ./verilog/FORMAL_Nto1_sync_fifo.v

./verilog/Nto1_sync_fifo.v: ../Nto1_sync_fifo.sv
	sv2v ../Nto1_sync_fifo.sv > ./verilog/Nto1_sync_fifo.v

clean:
	rm -rf ./verilog/*
