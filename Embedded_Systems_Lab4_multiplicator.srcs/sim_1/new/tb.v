`timescale 1ns/100ps
`define cycle 10   
module TB5;
  reg clk, rst, slv_reg_rden, slv_reg_wren;
  reg[15:0] X;
  wire[31:0] Y;
  //wire signal_computation_ready;
  integer i;
  integer arraysize=15;
  // Instantiate the System in the testbench  //Module #(params) InstanceName (...inputs&ouputs...)
  multiplicator System (.clk(clk), .rst(rst), .slv_reg_wren(slv_reg_wren), .slv_reg_rden(slv_reg_rden), .X(X), .signal_computation_ready(signal_computation_ready) , .Y(Y));
   initial 
     begin
          #(`cycle/2)
	      slv_reg_wren =0;
	      slv_reg_rden=0;
          rst = 1'b0;	  
	       clk = 1'b0 ;
          # (5*`cycle)
          rst = 1'b0;
          #(`cycle)
     ///////////////////////////////////////////idle
          slv_reg_wren=1;
          #(`cycle)
          slv_reg_wren=0;
          #(`cycle)
      ////////////////////////////////////////////set_vector_size
          X=arraysize;
          slv_reg_wren=1;
          #(`cycle)
          slv_reg_wren=0;
          #(`cycle)
      ////////////////////////////////////////sent_vector
          for (i=0; i<arraysize ; i=i+1) 
            begin
              X=i;
              slv_reg_wren=1;
              #(`cycle);
              slv_reg_wren=0;
              #(`cycle);
            end
      //////////////////////////////////////////waiting_signal for starting computation
          #(`cycle) //if this small delay here doesnt exist then the slv_reg_wren signal is lost in trantition  
          slv_reg_wren=1;
          #(`cycle)
          slv_reg_wren=0;
          #(`cycle)
       /////////////////////////////////////////fake wait: actually waiting module to sent compuation ready signal
          #(300*`cycle)
       ////////////////////////////////////////////receive vector
          for (i=0; i<arraysize ; i=i+1) 
            begin
              slv_reg_rden=1;
              #(`cycle);
              slv_reg_rden=0;
              #(`cycle);
            end

     end

  always 
      # (`cycle/2) clk = ~clk;
      

  
endmodule
