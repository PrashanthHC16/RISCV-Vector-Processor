`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2021 04:45:27 PM
// Design Name: 
// Module Name: Vector_Test_bench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Vector_Test_bench(

    );
    //parameter int Vlen = 32;    //vector length
	//parameter int Vlanes = 16;   //No. of Lanes
	//parameter int VSEW = 32;    //Std. Element Width
	
    reg clk;
    wire [31:0]Vec_Inst[6:1];
    wire [2:0]F_D_cycle;
    
    wire [31:0]V[4:1][32:1];
    wire [31:0]temp_store[2:1][16:1];
    
    int clk_count;
    
    
    //Trial3  dut3 (.*);
    Vec_Proc  dut3 (.*);
    
    initial begin
    clk=0;
    clk_count=0;
    end

    always@(posedge clk)
    clk_count=clk_count+1;

    always 
    begin
    #1 clk=~clk;
    $display ("clk=%d\t %d\n",clk_count,F_D_cycle);
    end

    initial
    #75 $finish;
    
    
endmodule
