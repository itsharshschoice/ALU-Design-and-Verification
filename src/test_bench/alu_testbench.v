`timescale 1ns / 1ps

module alu_testbench2;

    // DUT signals
    reg [7:0] OPA, OPB;
    reg CLK, RST, CE, MODE, CIN;
    reg [1:0] INV;
    reg [3:0] CMD;
    wire [15:0] RES_dut;
    wire COUT_dut, OFLOW_dut, G_dut, E_dut, L_dut, ERR_dut;

    // Reference model signals
    wire [15:0] RES_ref;
    wire COUT_ref, OFLOW_ref, G_ref, E_ref, L_ref, ERR_ref;

    reg [15:0] RES_hold;
    reg COUT_hold, OFLOW_hold, G_hold, E_hold, L_hold, ERR_hold;
    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;
    integer  log_file2;

     alu6 #(.WIDTH(8), .CMD_WIDTH(4)) m1(.CLK(CLK),.RST(RST),.MODE(MODE),.CE(CE),.CIN(CIN),
        .OPA(OPA),.OPB(OPB),.INP_VALID(INV), .CMD(CMD),
        .RES(RES_dut), .OFLOW(OFLOW_dut),.COUT(COUT_dut), .G(G_dut), .L(L_dut), .E(E_dut), .ERR(ERR_dut));


    // Reference model instantiation
    alu_reference_model #(.WIDTH(8)) m2(
        .OPA(OPA), .OPB(OPB), .CIN(CIN),
        .MODE(MODE), .CMD(CMD),
        .RES(RES_ref),.IN_V(INV),
        .COUT(COUT_ref), .OFLOW(OFLOW_ref),
        .G(G_ref), .E(E_ref), .L(L_ref),
        .ERR(ERR_ref)
    );



        task fdisplay_mismatch_rst();
        begin
            $fdisplay(log_file2, "  DUT: RES=0x%h COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
                     RES_dut, COUT_dut, OFLOW_dut, G_dut, E_dut, L_dut, ERR_dut);
        end
    endtask
    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    // Test stimulus
    initial begin

        log_file2 = $fopen("log_file2.txt", "w");
        if (log_file2 == 0) begin
            $display("ERROR: Could not open log file");
            $finish;
        end

        // Initialize
        RST = 1; CE = 1'b1; CIN = 0;
        OPA = 0; OPB = 0; MODE = 0; CMD = 0;INV=2'b11;

        @(negedge CLK);
        @(posedge CLK);
        test_reset("RESET");
        RST = 0;  // Release reset
        @(posedge CLK);
        $fdisplay(log_file2, "\n=== INPUT_VALID=2'b11 ===");
        // Test Arithmetic Operations
        $fdisplay(log_file2, "\n=== Testing Arithmetic Operations (MODE=1) ===");
        MODE = 1;
        test_arithmetic();

        // Test Logical Operations
        $fdisplay(log_file2, "\n=== Testing Logical Operations (MODE=0) ===");
        MODE = 0;
        test_logical();

        $fdisplay(log_file2, "\n=== Testing MULTIPLICATION Operations (MODE=1) ===");
        MODE = 1;
        test_mult();

        $fdisplay(log_file2, "\n=== HOLD OPERATION ===");
        // Test Arithmetic Operations
        @(posedge CLK);
        test_hold();
        $fdisplay(log_file2, "\n=== Testing Arithmetic Operations (MODE=1) ===");
        MODE = 1;
        test_arithmetic();

        // Test Logical Operations
        $fdisplay(log_file2, "\n=== Testing Logical Operations (MODE=0) ===");
        MODE = 0;
        test_logical();

        $fdisplay(log_file2, "\n=== Testing MULTIPLICATION Operations (MODE=1) ===");
        MODE = 1;
        test_mult();


        @(negedge CLK);
        CE=1'b1;
        @(posedge CLK);
        // Summary
        INV=2'b00;
        @(posedge CLK);
        $fdisplay(log_file2, "\n=== INPUT_VALID=2'b00 ===");
        // Test Arithmetic Operations
        $fdisplay(log_file2, "\n=== Testing Arithmetic Operations (MODE=1) ===");
        MODE = 1;
        test_arithmetic();

        // Test Logical Operations
        $fdisplay(log_file2, "\n=== Testing Logical Operations (MODE=0) ===");
        MODE = 0;
        test_logical();

        $fdisplay(log_file2, "\n=== Testing MULTIPLICATION Operations (MODE=1) ===");
        MODE = 1;
        test_mult();

        // Summary
        INV=2'b01;
        @(posedge CLK);
        $fdisplay(log_file2, "\n=== INPUT_VALID=2'b01 ===");
        // Test Arithmetic Operations
        $fdisplay(log_file2, "\n=== Testing Arithmetic Operations (MODE=1) ===");
        MODE = 1;
        test_arithmetic();

        // Test Logical Operations
        $fdisplay(log_file2, "\n=== Testing Logical Operations (MODE=0) ===");
        MODE = 0;
        test_logical();

        $fdisplay(log_file2, "\n=== Testing MULTIPLICATION Operations (MODE=1) ===");
        MODE = 1;
        test_mult();

        // Summary
        INV=2'b10;
        @(posedge CLK);
        $fdisplay(log_file2, "\n=== INPUT_VALID=2'b10 ===");
        // Test Arithmetic Operations
        $fdisplay(log_file2, "\n=== Testing Arithmetic Operations (MODE=1) ===");
        MODE = 1;
        test_arithmetic();

        // Test Logical Operations
        $fdisplay(log_file2, "\n=== Testing Logical Operations (MODE=0) ===");
        MODE = 0;
        test_logical();

        $fdisplay(log_file2, "\n=== Testing MULTIPLICATION Operations (MODE=1) ===");
        MODE = 1;
        test_mult();

        $fdisplay(log_file2, "\n=== TEST SUMMARY ===");
        $fdisplay(log_file2, "Total Tests: %0d", test_count);
        $fdisplay(log_file2, "PASS: %0d", pass_count);
        $fdisplay(log_file2, "FAIL: %0d", fail_count);

        if (fail_count == 0)
            $fdisplay(log_file2, "\n*** ALL TESTS PASSED ***\n");
        else
            $fdisplay(log_file2, "\n*** SOME TESTS FAILED ***\n");

        #1000;
        $fclose(log_file2);
        $finish;
    end

    task test_hold();
        begin
            @(negedge CLK);
            CE=1'b0;
            RES_hold<=RES_dut;
            COUT_hold<=COUT_dut;
            OFLOW_hold<=OFLOW_dut;
            G_hold<=G_dut;
            E_hold<=E_dut;
            L_hold<=L_dut;
            ERR_hold<=ERR_dut;
            @(posedge CLK);
            @(posedge CLK);
        end
    endtask
    // Test arithmetic operations
    task test_arithmetic();
        begin
            // ADD
            apply_test(8'h0F, 8'h11, 4'b0000, "ADD");
            apply_test(8'hFF, 8'h01, 4'b0000, "ADD (carry)");

            // SUB
            apply_test(8'h20, 8'h10, 4'b0001, "SUB");
            apply_test(8'h10, 8'h20, 4'b0001, "SUB (overflow)");

            // ADD_CIN
            CIN = 1;
            apply_test(8'h10, 8'h20, 4'b0010, "ADD_CIN");
            CIN = 0;
            apply_test(8'h10, 8'h20, 4'b0010, "ADD_CIN");

            // ADD_CIN
            CIN = 1;
            apply_test(8'hF0, 8'h20, 4'b0010, "ADD_CIN(carry)");
            CIN = 0;
            apply_test(8'hF0, 8'h20, 4'b0010, "ADD_CIN(carry)");

            // SUB_CIN
            CIN = 1;
            apply_test(8'h10, 8'h20, 4'b0011, "SUB_CIN(overflow)");
            CIN = 0;
            apply_test(8'h10, 8'h20, 4'b0011, "SUB_CIN(overflow)");

            // SUB_CIN
            CIN = 1;
            apply_test(8'hF0, 8'h20, 4'b0011, "SUB_CIN");
            CIN = 0;
            apply_test(8'hF0, 8'h20, 4'b0011, "SUB_CIN");

            // INC_A, DEC_A
            apply_test(8'h00, 8'h00, 4'b0100, "INC_A");
            apply_test(8'hFF, 8'h00, 4'b0100, "INC_A");

            apply_test(8'h0F, 8'h00, 4'b0101, "DEC_A");
            apply_test(8'h00, 8'h00, 4'b0101, "DEC_A");

            // INC_A, DEC_A
            apply_test(8'h00, 8'h00, 4'b0110, "INC_B");
            apply_test(8'h00, 8'hFF, 4'b0110, "INC_B");

            apply_test(8'h00, 8'h00, 4'b0111, "DEC_B");
            apply_test(8'h00, 8'hFF, 4'b0111, "DEC_B");

            // CMP
            apply_test(8'h10, 8'h10, 4'b1000, "CMP (equal)");
            apply_test(8'h20, 8'h10, 4'b1000, "CMP (greater)");
            apply_test(8'h10, 8'h20, 4'b1000, "CMP (less)");


            apply_test(8'h5A, 8'h0C, 4'b1011, "sign add positive ");
            apply_test(8'h5A, 8'h5C, 4'b1011, "sign add positive (overflow)");
            apply_test(8'hAA, 8'h0C, 4'b1011, "sign add negative ");
            apply_test(8'hAA, 8'hAC, 4'b1011, "sign add negative (overflow)");

            apply_test(8'h5A, 8'hF4, 4'b1100, "sign sub positive ");
            apply_test(8'h5A, 8'hA4, 4'b1100, "sign sub positive (overflow)");
            apply_test(8'hAA, 8'hF4, 4'b1100, "sign sub negative ");
            apply_test(8'hAA, 8'h54, 4'b1100, "sign sub negative (overflow)");

            //ERROR
            apply_test(8'hAA, 8'hFB, 4'b1101, "ERROR");
            apply_test(8'hAA, 8'hFB, 4'b1110, "ERROR");
            apply_test(8'hAA, 8'hFB, 4'b1111, "ERROR");
        end
    endtask



    // Test logical operations
    task test_logical();
        begin
            apply_test(8'hF0, 8'h0F, 4'b0000, "AND");
            apply_test(8'hF0, 8'h0F, 4'b0001, "NAND");
            apply_test(8'hF0, 8'h0F, 4'b0010, "OR");
            apply_test(8'hF0, 8'h0F, 4'b0011, "NOR");
            apply_test(8'hAA, 8'h55, 4'b0100, "XOR");
            apply_test(8'hAA, 8'h55, 4'b0101, "XNOR");
            apply_test(8'hF0, 8'h00, 4'b0110, "NOT_A");
            apply_test(8'hF0, 8'h0A, 4'b0111, "NOT_B");
            // INC_A, DEC_A
            apply_test(8'h01, 8'h00, 4'b1000, "RS_A");
            apply_test(8'h80, 8'h00, 4'b1000, "RS_A");
            apply_test(8'h01, 8'h00, 4'b1001, "LS_A");
            apply_test(8'h80, 8'h00, 4'b1001, "LS_A");

            // INC_A, DEC_A
            apply_test(8'h00, 8'h01, 4'b1010, "RS_B");
            apply_test(8'h00, 8'h80, 4'b1010, "RS_B");
            apply_test(8'h00, 8'h01, 4'b1011, "LS_B");
            apply_test(8'h00, 8'h80, 4'b1011, "LS_B");

            // CMP
            apply_test(8'hAA, 8'h00, 4'b1100, "ROL");
            apply_test(8'hAA, 8'h01, 4'b1100, "ROL");
            apply_test(8'hAA, 8'h02, 4'b1100, "ROL");
            apply_test(8'hAA, 8'h03, 4'b1100, "ROL");
            apply_test(8'hAA, 8'h04, 4'b1100, "ROL");
            apply_test(8'hAA, 8'h05, 4'b1100, "ROL");
            apply_test(8'hAA, 8'h06, 4'b1100, "ROL");
            apply_test(8'hAA, 8'h07, 4'b1100, "ROL");
            apply_test(8'hAA, 8'h0B, 4'b1100, "ROL");
            apply_test(8'hAA, 8'hFB, 4'b1100, "ROL");
            apply_test(8'hAA, 8'h00, 4'b1101, "ROR");
            apply_test(8'hAA, 8'h01, 4'b1101, "ROR");
            apply_test(8'hAA, 8'h02, 4'b1101, "ROR");
            apply_test(8'hAA, 8'h03, 4'b1101, "ROR");
            apply_test(8'hAA, 8'h04, 4'b1101, "ROR");
            apply_test(8'hAA, 8'h05, 4'b1101, "ROR");
            apply_test(8'hAA, 8'h06, 4'b1101, "ROR");
            apply_test(8'hAA, 8'h07, 4'b1101, "ROR");
            apply_test(8'hAA, 8'h0B, 4'b1101, "ROR");
            apply_test(8'hAA, 8'hFB, 4'b1101, "ROR");

            //Error
            apply_test(8'hAA, 8'hFB, 4'b1110, "ERROR");
            apply_test(8'hAA, 8'hFB, 4'b1111, "ERROR");

        end
    endtask



task test_mult();
        begin
            apply_test_mul(8'hFF, 8'hFF, 4'b1001, "MULT-CMD9");
            apply_test_mul(8'hF0, 8'h0F, 4'b1001, "MULT-CMD9");
            apply_test_mul(8'h00, 8'h00, 4'b1010, "MULT-CMD10");
            apply_test_mul(8'hF0, 8'h0F, 4'b1010, "MULT-CMD10");
            apply_test_mul(8'hFF, 8'hFF, 4'b1010, "MULT-CMD10");
        end
    endtask

    task apply_test_mul(
        input [7:0] a, b,
        input [3:0] cmd,
        input [80*8:1] test_name
    );
        begin
            @(negedge CLK);
            OPA = a;
            OPB = b;
            CMD = cmd;

            @(posedge CLK);
            @(posedge CLK);
            #1;
            if (CE) begin
                if((RES_dut!=={2*8{1'b0}})&&(INV==2'b11)) begin
                    $fdisplay(log_file2, "[FAIL-x] %s: OPA=0x%h OPB=0x%h CMD=0x%h",test_name, a, b, cmd);
                    test_count = test_count + 1;
                    fail_count = fail_count + 1;
                    fdisplay_mismatch();
                end else begin
                    @(posedge CLK);
                    #1;
                    test_count = test_count + 1;
                    if (compare_outputs(COUT_dut, COUT_ref)) begin
                        $fdisplay(log_file2, "[PASS] %s: OPA=0x%h OPB=0x%h CMD=0x%h",test_name, a, b, cmd);
                        pass_count = pass_count + 1;
                        fdisplay_mismatch();
                    end else begin
                        $fdisplay(log_file2, "[FAIL] %s: OPA=0x%h OPB=0x%h CMD=0x%h",test_name, a, b, cmd);
                        fdisplay_mismatch();
                        fail_count = fail_count + 1;
                    end
                    @(posedge CLK);
                end
             end else begin
                @(posedge CLK);
                test_count = test_count + 1;
                if (compare_hold(COUT_dut, COUT_ref)) begin
                    $fdisplay(log_file2, "[PASS] %s: OPA=0x%h OPB=0x%h CMD=0x%h",test_name, a, b, cmd);
                    pass_count = pass_count + 1;
                    fdisplay_mismatch();
                end else begin
                    $fdisplay(log_file2, "[FAIL] %s: OPA=0x%h OPB=0x%h CMD=0x%h",test_name, a, b, cmd);
                    fdisplay_mismatch();
                    fail_count = fail_count + 1;
                end
             end
        end
    endtask

    // Apply test and check
    task apply_test(
        input [7:0] a, b,
        input [3:0] cmd,
        input [80*8:1] test_name
    );
        begin
            @(negedge CLK);
            OPA = a;
            OPB = b;
            CMD = cmd;

            @(posedge CLK);
            @(posedge CLK);
            if (CE) begin
                test_count = test_count + 1;
                #1;
                if (compare_outputs(COUT_dut, COUT_ref)) begin
                    $fdisplay(log_file2, "[PASS] %s: OPA=0x%h OPB=0x%h CMD=0x%h",test_name,a, b, cmd);
                    pass_count = pass_count + 1;
                    fdisplay_mismatch();
                end else begin
                    $fdisplay(log_file2, "[FAIL] %s: OPA=0x%h OPB=0x%h CMD=0x%h",
                             test_name, a, b, cmd);
                    fdisplay_mismatch();
                    fail_count = fail_count + 1;
                end
            end else begin
                test_count = test_count + 1;
                if (compare_hold(COUT_dut, COUT_ref)) begin
                    $fdisplay(log_file2, "[PASS] %s: OPA=0x%h OPB=0x%h CMD=0x%h",test_name, a, b, cmd);
                    pass_count = pass_count + 1;
                    fdisplay_mismatch();
                end else begin
                    $fdisplay(log_file2, "[FAIL] %s: OPA=0x%h OPB=0x%h CMD=0x%h",test_name,a, b, cmd);
                    fdisplay_mismatch();
                    fail_count = fail_count + 1;
                end
            end
        end
    endtask

    task test_reset(input [80*8:1] test_name);
        begin
            test_count = test_count + 1;
            if ((COUT_dut!=1'b0)||(OFLOW_dut!=0)||(G_dut!=0)||(E_dut!=0)||(L_dut!=0)||(ERR_dut!=0)) begin
                $fdisplay(log_file2, "[FAIL] %s", test_name);
                fail_count = fail_count + 1;
                fdisplay_mismatch_rst();
            end else begin
                $fdisplay(log_file2, "[PASS] %s",test_name);
                pass_count = pass_count + 1;
                fdisplay_mismatch_rst();
            end
        end
    endtask


    // Compare DUT vs Reference
    function compare_outputs(input COUT_dut, input COUT_ref);
        begin
            compare_outputs = 1;

            // Compare RES (handle Z values)
            if (RES_dut !== RES_ref) begin
                if (!((RES_dut === 8'hxx) && (RES_ref === 8'hxx)))
                    compare_outputs = 0;
            end

            // Compare flags (handle Z values)
            if (!compare_bit(COUT_dut, COUT_ref)) compare_outputs = 0;
            if (!compare_bit(OFLOW_dut, OFLOW_ref)) compare_outputs = 0;
            if (!compare_bit(G_dut, G_ref)) compare_outputs = 0;
            if (!compare_bit(E_dut, E_ref)) compare_outputs = 0;
            if (!compare_bit(L_dut, L_ref)) compare_outputs = 0;
            if (!compare_bit(ERR_dut, ERR_ref)) compare_outputs = 0;
        end
    endfunction

    function compare_hold(input COUT_dut, input COUT_ref);
        begin
            compare_hold = 1;

            // Compare flags (handle Z values)
            if (!compare_bit(COUT_dut, COUT_hold)) compare_hold = 0;
            if (!compare_bit(OFLOW_dut, OFLOW_hold)) compare_hold = 0;
            if (!compare_bit(G_dut, G_hold)) compare_hold = 0;
            if (!compare_bit(E_dut, E_hold)) compare_hold = 0;
            if (!compare_bit(L_dut, L_hold)) compare_hold = 0;
            if (!compare_bit(ERR_dut, ERR_hold)) compare_hold = 0;
        end
    endfunction

    // Compare single bit (handle Z)
    function compare_bit(input dut, input ref);
        begin
            if (dut === ref)
                compare_bit = 1;
            else if ((dut === 1'bz) && (ref === 1'bz))
                compare_bit = 1;
            else
                compare_bit = 0;
        end
    endfunction

    // fdisplay mismatch details
    task fdisplay_mismatch();
        begin
            if (CE) begin
                $fdisplay(log_file2, "  DUT: RES=0x%h COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b", RES_dut, COUT_dut, OFLOW_dut, G_dut, E_dut, L_dut, ERR_dut);
                $fdisplay(log_file2, "  REF: RES=0x%h COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",RES_ref, COUT_ref, OFLOW_ref, G_ref, E_ref, L_ref, ERR_ref);
            end else begin
                $fdisplay(log_file2, "   DUT: RES=0x%h COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b", RES_dut, COUT_dut, OFLOW_dut, G_dut, E_dut, L_dut, ERR_dut);
                $fdisplay(log_file2, "  HELD: RES=0x%h COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b", RES_hold, COUT_hold, OFLOW_hold, G_hold, E_hold, L_hold, ERR_hold);
            end
        end
    endtask


    // Waveform dump
    initial begin
        $dumpfile("alu_test.vcd");
        $dumpvars(0, alu_testbench2);
    end

endmodule