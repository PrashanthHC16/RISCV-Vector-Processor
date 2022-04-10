`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/25/2021 12:15:32 PM
// Design Name: 
// Module Name: Vec_Proc
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


module Vec_Proc(
    input clk,
    output reg [31:0]Vec_Inst[6:1],
    output reg [2:0]F_D_cycle,
    output reg [31:0]V[4:1][32:1],    //Vector reg VA,VB,VC,VD
    output reg [31:0]temp_store[2:1][16:1]
    );
    
    parameter int Vlen = 32;    //vector length
	parameter int Vlanes = 16;  //No. of Lanes
	parameter int VSEW = 32;    //Std. Element Width
	
	reg [31:0]R[3:1];       //3 Architectural/scalar registers, 32-bit each.
    reg [31:0]I_mem[6:1];   //Instruction Memory
    reg [31:0]Mem[64:1];    //Data Memory
    
    reg [6:0]opcode[6:1];
    reg [4:0]S1_reg[6:1];
    reg [4:0]VS1_reg[6:1];
    reg [4:0]VS2_reg[6:1]; 
    reg [4:0]VD_reg[6:1];
    reg [2:0]funct3[6:1];
    reg [5:0]funct6[6:1];
    reg [2:0]nf[6:1];
    reg [2:0]mop[6:1];
    reg vm[6:1];            //Mask bit
    reg [4:0]lumop[6:1];
    reg [4:0]sumop[6:1];
    reg [2:0]load_width[6:1];
    reg [2:0]store_width[6:1];
    
    reg decode_complete[6:1];
    reg [2:0]I_num[6:1];
    reg [31:0]addr[2:1][4:1];
    
    reg load1_done[6:1];
    reg load2_done[6:1];
    reg addr1_done[6:1];
    reg addr2_done[6:1];
    reg mul1_done[6:1];
    reg mul2_done[6:1];
    reg store1_done[6:1];
    reg store2_done[6:1];
    reg dotprod1_done[6:1];
    reg dotprod2_done[6:1];
    
    reg Inst_done[6:0];
    reg [31:0]count_I[6:0];
    reg [31:0]temp_dotprod;
    integer load_state=0;
    integer store_state=0;
    integer addr_state=0;
    integer m,i,x,y,z,t,load_count,store_count,a;
    integer count; 
    initial 
    begin
        i=1;load_count=0;count=0;store_count=0;
        //Initialization of Scalar Registers
        R[1] = 32'h1 ;
        R[2] = 32'h3 ;
        R[3] = 32'h5 ;
        
        //Instruction Memory
        I_mem[1] = 32'b00000010000000001010000010000111;    //Vload va, (R1)    ///// Assumed unit-stride V.Load/Store
        I_mem[2] = 32'b00000010000000010010000100000111;    //Vload vb, (R2)    ///// Assumed unit-stride V.Load/Store
        I_mem[3] = 32'b00000010000100010000000111010111;    //VADD vc, va, vb   ///// Assumed Vector Int Op
        I_mem[4] = 32'b10010110000100011000001001010111;    //VMUL vd, va, vc   ///// Assumed Vector Int Op
        I_mem[5] = 32'b00000010000000011010000110100111;    //Vstore vc, (R3)   ///// Assumed unit-stride V.Load/Store
        I_mem[6] = 32'b11100110000100011000000011010111;    //Vdot va, va, vc   					

        
        //Data Memory Initialization
        for (m=1; m<=64; m=m+1)
        begin
            Mem[m] = m;
        end
        //Status bits Initialization
        for (m=1; m<=6; m=m+1)
        begin
            decode_complete[m]=0;
            load1_done[m]=0;
            load2_done[m]=0;
            addr1_done[m]=0;
            addr2_done[m]=0;
            Inst_done[m]=0;
        end
        Inst_done[0]=1;
        count_I[0]=0;
    end
    
    always@(posedge clk)
    begin
        count<=count+1;
 		//////////////////""" INSTRUCTION FETCH """/////////////////////////////////////
 		if (i <= 6)
        begin
            Vec_Inst[i] = I_mem[i] ;
            I_num[i]=i;
        /////////////////""" INSTRUCTION DECODE """/////////////////////////////////////
            opcode[i] = Vec_Inst[i][6:0];
            VD_reg[i] = Vec_Inst[i][11:7];        //decodes the Destination reg name.  In case of store: vs3
            
            vm[i] = Vec_Inst[i][25];
            case (opcode[i])
            7'b0000111:         //Vector Load 
                begin
                nf[i] = Vec_Inst[i][31:29];
                mop[i] = Vec_Inst[i][28:26];
                lumop[i] = Vec_Inst[i][24:20];
                load_width[i] = Vec_Inst[i][14:12];
                S1_reg[i] = Vec_Inst[i][19:15];      //decodes the Source-1 reg name.
                F_D_cycle=i;
                decode_complete[i]=1;
                //load_decode_complete=decode_complete[i];
                end
            7'b0100111:         //Vector Store 
                begin
                nf[i] = Vec_Inst[i][31:29];
                mop[i] = Vec_Inst[i][28:26];
                sumop[i] = Vec_Inst[i][24:20];
                store_width[i] = Vec_Inst[i][14:12];
                S1_reg[i] = Vec_Inst[i][19:15];      //decodes the Source-1 reg name.
                F_D_cycle=i;
                decode_complete[i]=1;
                end
            7'b1010111:         //Arithmetic operation
                begin
                funct6[i] = Vec_Inst[i][31:26];
                funct3[i] = Vec_Inst[i][14:12];
                VS1_reg[i] = Vec_Inst[i][19:15];  //decodes the V-Source-1 reg name.
                VS2_reg[i] = Vec_Inst[i][24:20];  //decodes the V-Source-2 reg name if the operation is ADD/SUB/MUL.
                F_D_cycle=i;
                decode_complete[i]=1;
                end
            endcase
        i=i+1;
        end    ///end of if i<=5
    end         //// end of always   
    
    ////////////////////////////""" LOAD EXECUTION """//////////////////////////////
    integer g;
    initial g=1;
    always@(count)
    begin
        if (opcode[g]==7'b0000111)
        begin
            if (decode_complete[g]==1)
            begin
                if (Inst_done[g-1]==1)
                begin
                    if (count==((I_num[g])+(count_I[g-1]+6)))
                    begin
                        count_I[g]=count-I_num[g];
                        addr[g][1] = R[S1_reg[g]];
                        for(y=1;y<=16;y=y+1)
                        begin
                            V[VD_reg[g]][y]=Mem[addr[g][1]+(y-1)];
                            load1_done[g]=1;
                        end
                    end
                    else if (count==((I_num[g])+(count_I[g-1]+7)))
                    begin
                        addr[g][2] = R[S1_reg[g]]+16;
                        for(y=1;y<=16;y=y+1)
                        begin
                            V[VD_reg[g]][16+y]=Mem[addr[g][2]+(y-1)];
                            load2_done[g]=1;
                            if ((load1_done[g]==1)&&(load2_done[g]==1))
                                Inst_done[g]=1;
                        end
                    end
                end
            end
        end
        if (Inst_done[g]==1)
            g=g+1;
        if (g>6) g=1;
    end
    
    ////////////////////////////""" ADD EXECUTION """//////////////////////////////
    integer h;
    initial h=1;
    always@(count)
    begin
        if (opcode[h]==7'b1010111)
        begin
            if (decode_complete[h]==1)
            begin
                if (Inst_done[h-1]==1)
                begin
                    if (funct6[h] == 6'h0)
                    begin
                        if (count==((I_num[h])+(count_I[h-1]+2)))
                        begin
                            count_I[h]=count-I_num[h];
                            for(x=1;x<=16;x=x+1)
                            begin
                                V[VD_reg[h]][x]=V[VS1_reg[h]][x]+V[VS2_reg[h]][x];
                                addr1_done[h]=1;
                            end
                        end
                        else if (count==((I_num[h])+(count_I[h-1]+3)))
                        begin
                            for(x=1;x<=16;x=x+1)
                            begin
                                V[VD_reg[h]][16+x]=V[VS1_reg[h]][16+x]+V[VS2_reg[h]][16+x];
                                addr2_done[h]=1;
                                if ((addr1_done[h]==1)&&(addr2_done[h]==1))
                                    Inst_done[h]=1;
                            end
                        end
                    end
                end
            end
        end
        if (Inst_done[h]==1)
            h=h+1;
        if (h>6) h=1;
    end
    
    ////////////////////////////""" MULTIPLICATION EXECUTION """//////////////////////////////
    integer j;
    initial j=1;
    always@(count)
    begin
        if (opcode[j]==7'b1010111)
        begin
            if (decode_complete[j]==1)
            begin
                if (Inst_done[j-1]==1)
                begin
                    if (funct6[j] == 6'b100101)
                    begin
                        if (count==((I_num[j])+(count_I[j-1]+2)))
                        begin
                            count_I[j]=count-I_num[j];
                            for(z=1;z<=16;z=z+1)
                            begin
                                V[VD_reg[j]][z]=V[VS1_reg[j]][z]*V[VS2_reg[j]][z];
                                mul1_done[j]=1;
                            end
                        end
                        else if (count==((I_num[j])+(count_I[j-1]+3)))
                        begin
                            for(z=1;z<=16;z=z+1)
                            begin
                                V[VD_reg[j]][16+z]=V[VS1_reg[j]][16+z]*V[VS2_reg[j]][16+z];
                                mul2_done[j]=1;
                                if ((mul1_done[j]==1)&&(mul2_done[j]==1))
                                    Inst_done[j]=1;
                            end
                        end
                    end
                end
            end
        end
        if (Inst_done[j]==1)
            j=j+1;
        if (j>6) j=1;
    end
    
    ////////////////////////////""" STORE EXECUTION """//////////////////////////////
    integer s;
    initial s=1;
    always@(count)
    begin
        if (opcode[s]==7'b0100111)
        begin
            if (decode_complete[s]==1)
            begin
                if (Inst_done[s-1]==1)
                begin
                    if (count==((I_num[s])+(count_I[s-1]+5)))
                    begin
                        count_I[s]=count-I_num[s];
                        addr[s][1] = R[S1_reg[s]];
                        for(t=1;t<=16;t=t+1)
                        begin
                            Mem[addr[s][1]+(t-1)] <= V[VD_reg[s]][t];
                            temp_store[1][t] <= V[VD_reg[s]][t];
                            store1_done[s]=1;
                        end
                    end
                    else if (count==((I_num[s])+(count_I[s-1]+6)))
                    begin
                        addr[s][2] = R[S1_reg[s]]+16;
                        for(t=1;t<=16;t=t+1)
                        begin
                            Mem[addr[s][2]+(t-1)] <= V[VD_reg[s]][16+t];
                            temp_store[2][t] <= V[VD_reg[s]][16+t];
                            store2_done[s]=1;
                            if ((store1_done[s]==1)&&(store2_done[s]==1))
                                Inst_done[s]=1;
                        end
                    end
                end
            end
        end
        if (Inst_done[s]==1)
            s=s+1;
        if (s>6) s=1;
    end   
    
    ////////////////////////////""" DOT PRODUCT EXECUTION """//////////////////////////////
    integer d,p;
    initial d=1;
    always@(count)
    begin
        if (opcode[d]==7'b1010111)
        begin
            if (decode_complete[d]==1)
            begin
                if (Inst_done[d-1]==1)
                begin
                    if (funct6[d] == 6'b111001)
                    begin
                        if (count==((I_num[d])+(count_I[d-1]+2)))
                        begin
                            count_I[d]=count-I_num[d];
                            for(p=1;p<=16;p=p+1)
                            begin
                                temp_dotprod=V[VS1_reg[d]][p]*V[VS2_reg[d]][p];
                                V[VD_reg[d]][p]=V[VD_reg[d]][p]+temp_dotprod;
                                dotprod1_done[d]=1;
                            end
                        end
                        else if (count==((I_num[d])+(count_I[d-1]+3)))
                        begin
                            for(p=1;p<=16;p=p+1)
                            begin
                                temp_dotprod=V[VS1_reg[d]][16+p]*V[VS2_reg[d]][16+p];
                                V[VD_reg[d]][16+p]=V[VD_reg[d]][16+p]+temp_dotprod;
                                dotprod2_done[d]=1;
                                if ((dotprod1_done[d]==1)&&(dotprod2_done[d]==1))
                                    Inst_done[d]=1;
                            end
                        end
                    end
                end
            end
        end
        if (Inst_done[d]==1)
            d=d+1;
        if (d>6) d=1;
    end
    
endmodule
