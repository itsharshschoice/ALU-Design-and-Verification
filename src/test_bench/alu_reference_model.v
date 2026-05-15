`timescale 1ns / 1ps

module alu_reference_model #(parameter WIDTH=8)(
    input [WIDTH-1:0] OPA, OPB,
    input CIN, MODE,
    input [1:0] IN_V,
    input [3:0] CMD,
    output reg [2*WIDTH-1:0] RES,
    output reg COUT, OFLOW, G, E, L, ERR
);

    reg [WIDTH-1:0] OPA_1, OPB_1;


    always @(*) begin
            RES = {(2*WIDTH){1'b0}};
            COUT = 1'b0;
            OFLOW = 1'b0;
            G = 1'b0;
            E = 1'b0;
            L = 1'b0;
            ERR = 1'b0;

        if (MODE) begin  // Arithmetic Mode
            case(CMD)
                4'b0000: begin  // ADD
                    if (IN_V==2'b11) begin
                    RES = OPA + OPB;
                    COUT = RES[WIDTH];
                    end else begin
                        ERR=1'b1;
                    end
                end
                4'b0001: begin  // SUB
                if (IN_V==2'b11) begin
                    OFLOW = (OPA < OPB);
                    RES = OPA - OPB;
                end else begin
                        ERR=1'b1;
                    end
                end
                4'b0010: begin  // ADD_CIN
                if (IN_V==2'b11) begin
                    RES = OPA + OPB + CIN;
                    COUT = RES[8];
                    end else begin
                        ERR=1'b1;
                    end
                end
                4'b0011: begin  // SUB_CIN
                if (IN_V==2'b11) begin
                    OFLOW = (OPA < (OPB+CIN));
                    RES = OPA - OPB - CIN;
                    end else begin
                        ERR=1'b1;
                    end
                end
                4'b0100: begin
                if ((IN_V==2'b11)||(IN_V==2'b01)) begin
                    RES[WIDTH-1:0] = OPA + 1;  // INC_A
                    end else begin
                        ERR=1'b1;
                    end
                 end
                4'b0101: begin
                if ((IN_V==2'b11)||(IN_V==2'b01)) begin
                    RES[WIDTH-1:0] = OPA - 1;  // DEC_A
                    end else begin
                        ERR=1'b1;
                    end
                    end
                4'b0110:begin
                if ((IN_V==2'b11)||(IN_V==2'b10)) begin
                 RES[WIDTH-1:0] = OPB + 1;  // INC_B
                end else begin
                        ERR=1'b1;
                    end
                    end
                4'b0111:begin
                 if ((IN_V==2'b11)||(IN_V==2'b10)) begin
                     RES[WIDTH-1:0] = OPB - 1;  // DEC_B
                     end else begin
                        ERR=1'b1;
                    end
                    end
                4'b1000: begin  // CMP
                 if (IN_V==2'b11) begin
                    if (OPA == OPB) begin
                        E = 1'b1; G = 1'b0; L = 1'b0;
                    end else if (OPA > OPB) begin
                        E = 1'b0; G = 1'b1; L = 1'b0;
                    end else begin
                        E = 1'b0; G = 1'b0; L = 1'b1;
                    end
                   end else begin
                        ERR=1'b1;
                    end
                end
                4'b1001:begin
                    if (IN_V==2'b11) begin
                        RES=((OPA+1)*(OPB+1));

                end else begin
                    ERR=1'b1;
                end
            end
                4'b1010:begin
                    if (IN_V==2'b11) begin
                        RES=(({OPA[WIDTH-2:0],1'b0})*(OPB));

                end else begin
                    ERR=1'b1;
                end
                end
                4'b1011:begin
                    if (IN_V==2'b11) begin
                                        RES=$signed(OPA)+$signed(OPB);
                                        OFLOW=((OPA[WIDTH-1]==OPB[WIDTH-1])&&(OPA[WIDTH-1]!=RES[WIDTH-1]));
                                        G     <= ($signed(OPA) > $signed(OPB));
                                        L     <= ($signed(OPA) < $signed(OPB));
                                        E     <= ($signed(OPA) == $signed(OPB));
                                        if (OFLOW) RES[2*WIDTH-1:WIDTH]={WIDTH{!RES[WIDTH-1]}};
                                end else begin
                                        ERR=1'b1;
                                end
                end
                4'b1100:begin
                    if (IN_V==2'b11) begin
                                        RES=$signed(OPA)-$signed(OPB);
                                        OFLOW=((OPA[WIDTH-1]!=OPB[WIDTH-1])&&(OPA[WIDTH-1]!=RES[WIDTH-1]));
                                        G     <= ($signed(OPA) > $signed(OPB));
                                        L     <= ($signed(OPA) < $signed(OPB));
                                        E     <= ($signed(OPA) == $signed(OPB));
                                        if (OFLOW) RES[2*WIDTH-1:WIDTH]={WIDTH{!RES[WIDTH-1]}};
                                end else begin
                                        ERR=1'b1;
                                end
                end
                default:ERR=1'b1;
            endcase
        end
        else begin  // Logical Mode
            case(CMD)
                4'b0000:if(IN_V==2'b11) RES = {{WIDTH{1'b0}} , OPA & OPB};   else ERR=1'b1;    // AND
                4'b0001:if(IN_V==2'b11) RES = {{WIDTH{1'b0}}, ~(OPA & OPB)}; else ERR=1'b1;   // NAND
                4'b0010:if(IN_V==2'b11) RES = {{WIDTH{1'b0}}, OPA | OPB};    else ERR=1'b1;   // OR
                4'b0011:if(IN_V==2'b11) RES = {{WIDTH{1'b0}}, ~(OPA | OPB)}; else ERR=1'b1;   // NOR
                4'b0100:if(IN_V==2'b11) RES = {{WIDTH{1'b0}}, OPA ^ OPB};    else ERR=1'b1;   // XOR
                4'b0101:if(IN_V==2'b11) RES = {{WIDTH{1'b0}}, ~(OPA ^ OPB)}; else ERR=1'b1;   // XNOR
                4'b0110:if((IN_V==2'b11)||(IN_V==2'b01)) RES = {{WIDTH{1'b0}}, ~OPA};     else ERR=1'b1;       // NOT_A
                4'b0111:if((IN_V==2'b11)||(IN_V==2'b10)) RES = {{WIDTH{1'b0}}, ~OPB};     else ERR=1'b1;       // NOT_B
                4'b1000:if((IN_V==2'b11)||(IN_V==2'b01)) RES = {{WIDTH{1'b0}}, OPA >> 1}; else ERR=1'b1;       // SHR1_A
                4'b1001:if((IN_V==2'b11)||(IN_V==2'b01)) RES = {{WIDTH{1'b0}}, OPA << 1}; else ERR=1'b1;       // SHL1_A
                4'b1010:if((IN_V==2'b11)||(IN_V==2'b10)) RES = {{WIDTH{1'b0}}, OPB >> 1}; else ERR=1'b1;       // SHR1_B
                4'b1011:if((IN_V==2'b11)||(IN_V==2'b10)) RES = {{WIDTH{1'b0}}, OPB << 1}; else ERR=1'b1;       // SHL1_B
                4'b1100: begin  // ROL_A_B
                    if ((IN_V==2'b11)&&(OPB[WIDTH-1:($clog2(WIDTH)+1)]=={(WIDTH-1-($clog2(WIDTH))){1'b0}})) begin
                                        RES[WIDTH-1:0] = (OPA<<OPB[$clog2(WIDTH)-1:0]) | (OPA>>(WIDTH-OPB[$clog2(WIDTH)-1:0]));
                end else begin
                     ERR=1'b1;
                     RES[WIDTH-1:0] = (OPA<<OPB[$clog2(WIDTH)-1:0]) | (OPA>>(WIDTH-OPB[$clog2(WIDTH)-1:0]));
                end
                end
                4'b1101: begin  // ROR_A_B
                    if ((IN_V==2'b11)&&(OPB[WIDTH-1:($clog2(WIDTH)+1)]=={(WIDTH-1-($clog2(WIDTH))){1'b0}})) begin
                                        RES[WIDTH-1:0] = (OPA>>OPB[$clog2(WIDTH)-1:0]) | (OPA<<(WIDTH-OPB[$clog2(WIDTH)-1:0]));
                end else begin
                     ERR=1'b1;
                     RES[WIDTH-1:0] = (OPA>>OPB[$clog2(WIDTH)-1:0]) | (OPA<<(WIDTH-OPB[$clog2(WIDTH)-1:0]));
                end
                end
                default:ERR=1'b1;
            endcase

        end
    end

endmodule