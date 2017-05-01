`timescale 1ns / 1ps
module multiplicator(
    input clk,
    input rst,
    input slv_reg_wren,   //memWrite initiated, data is ready to take within 1 cycle on slv_reg0=X
    input slv_reg_rden,   //memRead initiated, data must be ready to give within 1 cycle on slv_reg1=Y
	input  [15:0] X,      //slv_reg0
	output reg signal_computation_ready, //slv_reg2
	output reg [31:0] Y=0   //slv_reg1 , initialized as 0
);

    parameter idle = 3'b000;
    parameter set_vector_size = 3'b001;
    parameter receive_vector = 3'b010;
    parameter waiting_signal = 3'b011;
    parameter computation = 3'b100;
    parameter sent_vector = 3'b101;
    reg [2:0] state=0;
    reg [2:0] nextstate=0;
    reg [15:0] vector_size; 
    reg [31:0] i; //simple counter for every register received or sent using the AXI interface.
    (* ram_style = "block" *) reg [31 : 0] memInputX [0 : 1023]; //max 1024 array input
    (* ram_style = "block" *) reg [31 : 0] memInputY [0 : 1023];



	
  always @(posedge clk) //should it be posedge clk to access Blockrams better??? It will not be an FSM if there is a clockedge
        begin
              case(state)
                  idle: //a) at the beginning, the accelerator is in idle (or RESET) state waiting for the first inputs to appear.
                            begin
                                i=0;
                                signal_computation_ready=0;
                              if(slv_reg_wren)
                                   begin
                                       nextstate=set_vector_size;
                                   end
                            end       
                  set_vector_size://b) The accelerator receives the size of the input (and output) arrays N. 
                           begin
                               i=0;
                               if(slv_reg_wren)
                                                     begin
                                                          vector_size=X;
                                                          nextstate=receive_vector;
                                                     end
                           end

                  receive_vector://c) The accelerator receives the input array X[.] and stores the elements of the array to the input SRAM. This phase will take N cycles to complete.
                              //pulse=0;
                              if(slv_reg_wren)
                                   begin
                                          memInputX[i]=X;
                                          i=i+1;    
                                          if (i==vector_size)
                                               begin
                                                   nextstate=waiting_signal;
                                                   i=0;
                                               end
                                               
                                  end         
                  waiting_signal://d) Once all input data arrive, the accelerator waits for the trigger signal to start computation.
                              if(slv_reg_wren)
                                   begin
                                       nextstate=computation;
                                   end
                    //takes half the time as receive_vector state: 1clock period for 1 multiplication+saving               
                  computation://e) Once triggered, the accelerator reads each element X[i], computes Y[i] = A*X[i]*X[i] and stores the result to the output SRAM.
                             if(i!=vector_size) //THIS SIGNAL READY SIGNAL SHOULD BE ABOUT THE BUS INTERFACE HAVING THE NEXT VECTOR
                               begin
                                    memInputY[i]=memInputX[i]*memInputX[i];
                                    i=i+1;
                               end
                             else
                               begin
                                        signal_computation_ready=1;//////signal CPU AS WELL Y=SIGNAL
                                        nextstate=sent_vector;
                                        i=0;
                               end
                              //for (j=0; j<=N ; j=j+1)  //: in case of fixed array size.
                                    //memInputY[j]=memInputX[j]*memInputX[j];
                                  
                  sent_vector://f) When finished, the accelerator reads the N Y[.] data from the output SRAM and presents
                  // them to the output port. At the same time, it asserts an output enable signal to show to the
                  //testbench that the data are available
                        begin
                           if(slv_reg_rden)
                                   begin
                                          Y=memInputY[i];
                                          i=i+1;  
                                          if (i==vector_size)
                                               begin
                                                   nextstate=idle;
                                                   i=0;
                                               end                                         
                                  end       
                        end
                  default: 
                         begin
                          i=0;
                          nextstate=idle;
                         end
              endcase
        end
        
        //Always blocks are executed as blocking statements in Simulation in sequence one after the other: CAUTION.
      always @(posedge clk, posedge rst)
              begin
                  if(rst)
                      state <= idle;
                  else
                      state <= nextstate;
      end
      
  endmodule
