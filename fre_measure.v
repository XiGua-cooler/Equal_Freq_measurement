//////////////////////////////////////////////////////////////////////////////////
// Engineer: XiGua
// 
// Create Date: 2021/05/2 11:22:02
// Module Name: iso-precision method
// Target Devices: ALL Xilinx FPGA
// Tool Versions: V1.0
// Description: 1.Frequency measurement using iso-precision method.
//              2.(Gate_time) means the lasting time of measurement.
// 
//////////////////////////////////////////////////////////////////////////////////
module fre_measure(
     input             std_clk,				//This is Standered signal. 
														//Default is 50MHz.
	  input             std_reset,			//Moudle reset pin.
	  input             signal_unknown,    //The signal that you mwant to measure should assign to this pin.
	  input             start_flag, 			//If you want start a measurement you should give a rising edge through this pin.
	  
	  output reg        end_flag, 			//This pin will generate a rising edge when a measurement over.
	  output reg[9:0]   fre_val 				//You can read the "signal_unknown" frequency through this interface. 
														//Unit is (MHz).
    );


parameter T_10ms = 28'd500_000;  //Setting the gate time.
											//Default is 10ms.
											//Unit is time.
											//Caculation: T_10ms = (Gate_time) / T("std_clk"). 
parameter FRE_50M = 28'd50;      //Indicating the frequency of "std_clk".
											//Unit is (MHz).

reg           en;
reg           temp_end_flag;
reg[27:0]     t_gate_cnt;
reg[31:0]     signal_cnt;
reg[31:0]     std_clk_cnt;
reg           real_gate;
reg           std_gate;
reg[2 :0]     measure_state;


//Generate end_flg from temp_end_flag
always@(posedge std_clk or negedge std_reset)begin
     if(!std_reset)begin
	       end_flag <= 1'b0;
	  end
	  else begin
	       end_flag <= temp_end_flag;
	  end
end
//State tramforance
always@(posedge std_clk or negedge std_reset)begin
     if(!std_reset)begin
	       measure_state <= 3'b000;    
          fre_val <= 10'd0; 	       
	  end
	  else begin
	       case(measure_state)
			 3'b000: begin
			      if(start_flag == 1'b1)begin
					     en <= 1'b1;
						  measure_state <= 3'b001;
					end
			 end
			 3'b001: begin
			      if(temp_end_flag == 1'b1)begin
					     fre_val <= (FRE_50M * signal_cnt) / std_clk_cnt;
						  en <= 1'b0;
						  measure_state <= 3'b000;
					end
					else begin
					     en <= 1'b1;
					     measure_state <= 3'b001; 
					end
			 end
			 default;
			 endcase
	  end
end

//Contral the gate time as 10ms.
always@(posedge std_clk or negedge std_reset)begin
     if(!std_reset)begin
	       t_gate_cnt <= 28'd0;
			 temp_end_flag <= 1'b0;
	  end
	  else if(en == 1'b1)begin
			 if(t_gate_cnt >= T_10ms)begin
					t_gate_cnt <= 28'd0;
					temp_end_flag <= 1'b1;
			 end
			 else begin
					t_gate_cnt <= t_gate_cnt + 1'd1;
					temp_end_flag <= 1'b0;
			 end
	  end
	  else begin
	       t_gate_cnt <= 28'd0;
			 temp_end_flag <= 1'b0;
	  end
end
//Generat the stdand gate signal.
always@(posedge std_clk or negedge std_reset)begin
     if(!std_reset)begin
	       std_gate <= 1'b0;
	  end
	  else if(en == 1'b1)begin
	       if(t_gate_cnt >= T_10ms)begin
			      std_gate <= ~std_gate;
			 end
			 else begin
			      std_gate <= 1'b1;
			 end
	  end
	  else begin
	       std_gate <= 1'b0;
	  end
end
//Generate the real gate signal.
always@(posedge std_clk or negedge std_reset)begin
     if(!std_reset)begin
	       real_gate <= 1'b0;
	  end
	  else if(en == 1'b1)begin
	       if(std_gate == 1'b1)begin
			      real_gate <= 1'b1;
			 end
			 else begin
			      real_gate <= 1'b0;
			 end
	  end
	  else begin
	       real_gate <= 1'b0;
	  end
end
//Count the unknown signal time.
always@(posedge signal_unknown or negedge std_reset)begin
     if(!std_reset)begin
	       signal_cnt <= 32'd0;
	  end
	  else if(en == 1'b1)begin
	       if(real_gate == 1'b1)begin
			      signal_cnt <= signal_cnt + 1'd1;
			 end
			 else begin
			      signal_cnt <= 32'd0;
			 end
	  end
	  else begin
	       signal_cnt <= 32'd0;
	  end
end
//Count the stander signal time.
always@(posedge std_clk or negedge std_reset)begin
     if(!std_reset)begin
	       std_clk_cnt <= 32'd0;
	  end
	  else if(en == 1'b1)begin
	       if(real_gate == 1'b1)begin
					std_clk_cnt <= std_clk_cnt + 1'd1;
			 end
			 else begin
					std_clk_cnt <= 32'd0;
			 end
	  end
	  else begin
	       std_clk_cnt <= 32'd0;
	  end
end
endmodule
