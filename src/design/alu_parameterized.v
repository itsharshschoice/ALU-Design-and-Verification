`timescale 1ns / 1ps

module alu_parameterized #(
    parameter n = 8, // operands width
    parameter m = 4  // command width (max 16 commands by default)
)(
    input  [n-1:0] OPA, OPB,  // operands
    input  CIN, // carry-in for addition/subtraction
    input  CLK, RST, // clock and reset
    input  CE, // control signal: CE = clock enable
    input  MODE, // control signal: MODE = 0 for logical, 1 for arithmetic
    input  [1:0] INP_VALID, // control signal: bit 0 for OPA valid, bit 1 for OPB valid
    input  [m-1:0] CMD, // control signal: command for instruction
    output reg ERR, OFLOW, COUT, // arithmetic op flags
    output reg G, L, E, // comparison op flags
    output reg [2*n-1:0] RES // result (twice the width of operands to accommodate multiplication results)
);

localparam SW = $clog2(n);  // Rotate width

//stage 1 registers
reg err_s1, oflow_s1, cout_s1, g_s1, l_s1, e_s1;
reg [2*n-1:0] res_s1;

// multiplication pipeline registers
reg [n-1:0]   mul_opa, mul_opb;
reg [2*n-1:0] mul_res;
reg [1:0]     mul_st; // 0: idle, 1: compute, 2: output
reg  mul_is9; // is cmd = 9 or cmd = 10
reg  mul_err; // multiplication error flag (both inputs are not valid)

wire rot_err = |OPB[n-1:SW+1];  // rotation error
wire [SW-1:0] rot_amt = OPB[SW-1:0];  // rotation amount

// unsigned addition results wires
wire [n:0]   add_u  = {1'b0, OPA} + {1'b0, OPB}; // we need 1 extra bit to capture the output carry
wire [n:0]   addc_u = {1'b0, OPA} + {1'b0, OPB} + CIN;

// signed operation results wires
wire [2*n-1:0] sadd_res = $signed(OPA) + $signed(OPB);
wire [2*n-1:0] ssub_res = $signed(OPA) - $signed(OPB);

// signed operation overflow wires
wire sadd_ovf = (OPA[n-1] == OPB[n-1]) && (sadd_res[n-1] != OPA[n-1]);
wire ssub_ovf = (OPA[n-1] != OPB[n-1]) && (ssub_res[n-1] != OPA[n-1]);

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        ERR   <= 1'b0;
        RES   <= {2*n{1'b0}};
        COUT  <= 1'b0;
        OFLOW <= 1'b0;
        G <= 1'b0;
        L <= 1'b0;
        E <= 1'b0;

        err_s1 <= 1'b0;
        res_s1 <= {2*n{1'b0}};
        cout_s1 <= 1'b0; 
        oflow_s1 <= 1'b0;
        g_s1 <= 1'b0; 
        l_s1 <= 1'b0; 
        e_s1 <= 1'b0;

        mul_st <= 2'd0; 
        mul_opa <= {n{1'b0}}; 
        mul_opb <= {n{1'b0}};
        mul_res <= {2*n{1'b0}}; 
        mul_is9 <= 1'b0; 
        mul_err <= 1'b0;
    end

    else if (CE) begin
        ERR   <= err_s1;
        RES   <= res_s1;
        COUT  <= cout_s1;
        OFLOW <= oflow_s1;
        G     <= g_s1;
        L     <= l_s1;
        E     <= e_s1;

        err_s1   <= 1'b0; 
        res_s1   <= {2*n{1'b0}};
        cout_s1  <= 1'b0; 
        oflow_s1 <= 1'b0;
        g_s1     <= 1'b0; 
        l_s1     <= 1'b0; 
        e_s1 <= 1'b0;

        if (MODE && (CMD == 4'd9 || CMD == 4'd10)) begin  // multiplication commands
            case (mul_st)
                2'd0: begin  // sample inputs 
                    mul_opa <= OPA;
                    mul_opb <= OPB;
                    mul_is9 <= (CMD == 4'd9);
                    mul_err <= (INP_VALID != 2'b11);
                    mul_st  <= 2'd1;
                end
                2'd1: begin
                    if (mul_err)
                        mul_res <= {2*n{1'b0}};
                    else if (mul_is9)
                        mul_res <= (mul_opa + 1'b1) * (mul_opb + 1'b1);
                    else
                        mul_res <= ({mul_opa[n-2:0], 1'b0}) * mul_opb;
                    mul_st <= 2'd2;
                end
                2'd2: begin
                    if (mul_err)
                        ERR <= 1'b1;
                    else
                        RES <= mul_res;

                    mul_opa <= OPA;
                    mul_opb <= OPB;
                    mul_is9 <= (CMD == 4'd9);
                    mul_err <= (INP_VALID != 2'b11);
                    mul_st  <= 2'd1;
                end
                default: mul_st <= 2'd0;
            endcase
        end

        else begin  // cmd != 9 or 10
            mul_st  <= 2'd0;
            mul_opa <= {n{1'b0}};
            mul_opb <= {n{1'b0}};
            mul_err <= 1'b0;

            if (MODE) begin  // arithmetic mode
                case (CMD)
                    4'd0: begin
                        if (INP_VALID == 2'b11) begin
                            res_s1  <= OPA + OPB;
                            cout_s1 <= add_u[n];
                        end
                        else err_s1 <= 1'b1;
                    end
                    4'd1: begin
                        if (INP_VALID == 2'b11) begin
                            res_s1   <= OPA - OPB;
                            oflow_s1 <= (OPB > OPA);
                        end
                        else err_s1 <= 1'b1;
                    end
                    4'd2: begin
                        if (INP_VALID == 2'b11) begin
                            res_s1  <= OPA + OPB + CIN;
                            cout_s1 <= addc_u[n];
                        end
                        else err_s1 <= 1'b1;
                    end
                    4'd3: begin
                        if (INP_VALID == 2'b11) begin
                            res_s1   <= OPA - OPB - CIN;
                            oflow_s1 <= ({1'b0, OPB} + CIN) > OPA;
                        end
                        else err_s1 <= 1'b1;
                    end
                    4'd4: begin
                        if (INP_VALID == 2'b01 || INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, OPA + 1'b1};
                        else err_s1 <= 1'b1;
                    end
                    4'd5: begin
                        if (INP_VALID == 2'b01 || INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, OPA - 1'b1};
                        else err_s1 <= 1'b1;
                    end
                    4'd6: begin
                        if (INP_VALID == 2'b10 || INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, OPB + 1'b1};
                        else err_s1 <= 1'b1;
                    end
                    4'd7: begin
                        if (INP_VALID == 2'b10 || INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, OPB - 1'b1};
                        else err_s1 <= 1'b1;
                    end
                    4'd8: begin
                        if (INP_VALID == 2'b11) begin
                            g_s1 <= (OPA > OPB);
                            l_s1 <= (OPA < OPB);
                            e_s1 <= (OPA == OPB);
                        end
                        else err_s1 <= 1'b1;
                    end
                    4'd11: begin
                        if (INP_VALID == 2'b11) begin
                            res_s1   <=  $signed(sadd_res);
                            oflow_s1 <= sadd_ovf;
                            //cout_s1  <= sadd_res[n-1];
                            g_s1     <= ($signed(OPA) > $signed(OPB));
                            l_s1     <= ($signed(OPA) < $signed(OPB));
                            e_s1     <= ($signed(OPA) == $signed(OPB));
                        end
                        else err_s1 <= 1'b1;
                    end
                    4'd12: begin
                        if (INP_VALID == 2'b11) begin
                            res_s1   <=  $signed(ssub_res);
                            oflow_s1 <= ssub_ovf;
                            //cout_s1  <= ssub_res[n-1];
                            g_s1     <= ($signed(OPA) > $signed(OPB));
                            l_s1     <= ($signed(OPA) < $signed(OPB));
                            e_s1     <= ($signed(OPA) == $signed(OPB));
                        end
                        else err_s1 <= 1'b1;
                    end
                    default: err_s1 <= 1'b1;
                endcase
            end

            else begin  // mode = 0
                case (CMD)
                    4'd0: begin
                        if (INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, OPA & OPB};
                        else err_s1 <= 1'b1;
                    end
                    4'd1: begin
                        if (INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, ~(OPA & OPB)};
                        else err_s1 <= 1'b1;
                    end
                    4'd2: begin
                        if (INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, OPA | OPB};
                        else err_s1 <= 1'b1;
                    end
                    4'd3: begin
                        if (INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, ~(OPA | OPB)};
                        else err_s1 <= 1'b1;
                    end
                    4'd4: begin
                        if (INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, OPA ^ OPB};
                        else err_s1 <= 1'b1;
                    end
                    4'd5: begin
                        if (INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, ~(OPA ^ OPB)};
                        else err_s1 <= 1'b1;
                    end
                    4'd6: begin
                        if (INP_VALID == 2'b01 || INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, ~OPA};
                        else err_s1 <= 1'b1;
                    end
                    4'd7: begin
                        if (INP_VALID == 2'b10 || INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, ~OPB};
                        else err_s1 <= 1'b1;
                    end
                    4'd8: begin
                        if (INP_VALID == 2'b01 || INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, 1'b0, OPA[n-1:1]};
                        else err_s1 <= 1'b1;
                    end
                    4'd9: begin
                        if (INP_VALID == 2'b01 || INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, OPA[n-2:0], 1'b0};
                        else err_s1 <= 1'b1;
                    end
                    4'd10: begin
                        if (INP_VALID == 2'b10 || INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, 1'b0, OPB[n-1:1]};
                        else err_s1 <= 1'b1;
                    end
                    4'd11: begin
                        if (INP_VALID == 2'b10 || INP_VALID == 2'b11)
                            res_s1 <= {{n{1'b0}}, OPB[n-2:0], 1'b0};
                        else err_s1 <= 1'b1;
                    end
                    4'd12: begin
                        if (INP_VALID == 2'b11) begin
                            err_s1 <= rot_err;
                            if (rot_amt == {SW{1'b0}})
                                res_s1 <= {{n{1'b0}}, OPA};
                            else
                                res_s1 <= {{n{1'b0}}, (OPA << rot_amt) | (OPA >> (n - rot_amt))};
                        end
                        else begin
                            res_s1 <= {{n{1'b0}}, (OPA << rot_amt) | (OPA >> (n - rot_amt))};
                            err_s1 <= 1'b1;
                        end
                    end
                    4'd13: begin
                        if (INP_VALID == 2'b11) begin
                            err_s1 <= rot_err;
                            if (rot_amt == {SW{1'b0}})
                                res_s1 <= {{n{1'b0}}, OPA};
                            else
                                res_s1 <= {{n{1'b0}}, (OPA >> rot_amt) | (OPA << (n - rot_amt))};
                        end
                        else begin
                            res_s1 <= {{n{1'b0}}, (OPA >> rot_amt) | (OPA << (n - rot_amt))};
                            err_s1 <= 1'b1;
                        end
                    end
                    default: err_s1 <= 1'b1;
                endcase
            end
        end

    end
end

endmodule