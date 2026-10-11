`timescale 1ns/1ps

module tb_pmod_da3_controller;

    // -------------------------------------------------
    // Testbench parameters
    // -------------------------------------------------
    localparam int CLK_PERIOD_NS = 10;
    localparam int CLK_FREQ_HZ   = 100_000_000;
    localparam int SCLK_FREQ_HZ  = 25_000_000;

    // -------------------------------------------------
    // DUT signals
    // -------------------------------------------------
    logic clk;
    logic rst;

    logic signed [15:0] sample_in;
    logic               sample_valid;

    logic sample_ready;
    logic sample_done;
    logic busy;

    logic dac_cs_n;
    logic dac_din;
    logic dac_ldac_n;
    logic dac_sclk;

    // -------------------------------------------------
    // Clock generation
    // -------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS/2) clk = ~clk;
    end

    // -------------------------------------------------
    // DUT instance
    // -------------------------------------------------
    pmod_da3_controller #(
        .CLK_FREQ_HZ  (CLK_FREQ_HZ),
        .SCLK_FREQ_HZ (SCLK_FREQ_HZ)
    ) dut (
        .clk          (clk),
        .rst          (rst),

        .sample_in    (sample_in),
        .sample_valid (sample_valid),

        .sample_ready (sample_ready),
        .sample_done  (sample_done),
        .busy         (busy),

        .dac_cs_n     (dac_cs_n),
        .dac_din      (dac_din),
        .dac_ldac_n   (dac_ldac_n),
        .dac_sclk     (dac_sclk)
    );

    // -------------------------------------------------
    // Reset task
    // -------------------------------------------------
    task automatic apply_reset(
        input int num_cycles = 3
    );
        begin
            rst = 1'b1;

            repeat (num_cycles)
                @(posedge clk);

            @(negedge clk);
            rst = 1'b0;
        end
    endtask

    // -------------------------------------------------
    // Sample transmission and verification task
    // -------------------------------------------------
    task automatic transmit_and_check(
        input logic signed [15:0] value
    );

        logic [15:0] expected_code;

        begin

            // Convert signed Q1.15 to offset binary
            expected_code = value ^ 16'h8000;

            // Wait until the controller is ready
            @(negedge clk);

            while (sample_ready !== 1'b1)
                @(negedge clk);

            // Apply a new sample
            sample_in    = value;
            sample_valid = 1'b1;

            // Keep valid asserted for one clock cycle
            @(negedge clk);
            sample_valid = 1'b0;

            // -----------------------------------------
            // Verify all 16 transmitted bits
            // -----------------------------------------
            for (int bit_idx = 15; bit_idx >= 0; bit_idx--) begin

                @(posedge dac_sclk);
                #1;

                // CS must remain active
                if (dac_cs_n !== 1'b0) begin
                    $fatal(1,
                        "ERROR: CS inactive during transmission");
                end

                // Compare transmitted and expected bit
                if (dac_din !== expected_code[bit_idx]) begin

                    $fatal(1,
                        "ERROR: Bit %0d. Expected=%b, Received=%b",
                        bit_idx,
                        expected_code[bit_idx],
                        dac_din
                    );

                end

            end

            // -----------------------------------------
            // Wait for transmission completion
            // -----------------------------------------
            @(posedge sample_done);
            #1;

            if (busy !== 1'b0)
                $fatal(1, "ERROR: Busy remains active");

            if (sample_ready !== 1'b1)
                $fatal(1, "ERROR: Controller is not ready");

            if (dac_cs_n !== 1'b1)
                $fatal(1, "ERROR: CS not released");

            if (dac_sclk !== 1'b0)
                $fatal(1, "ERROR: SCLK not idle");

            if (dac_ldac_n !== 1'b0)
                $fatal(1, "ERROR: Invalid LDAC state");

            // Verify that sample_done is a one-cycle pulse
            @(posedge clk);
            #1;

            if (sample_done !== 1'b0)
                $fatal(1, "ERROR: sample_done pulse too long");

            $display(
                "PASS: Q1.15=%h -> DAC=%h, Time=%0t",
                value,
                expected_code,
                $time
            );

        end
    endtask

    // -------------------------------------------------
    // Main stimulus
    // -------------------------------------------------
    initial begin

        rst          = 1'b1;
        sample_in    = 16'sd0;
        sample_valid = 1'b0;

        apply_reset(4);

        // Test signed Q1.15 conversion
        transmit_and_check(16'sh8000); // -1.0
        transmit_and_check(16'shC000); // -0.5
        transmit_and_check(16'sh0000); //  0.0
        transmit_and_check(16'sh4000); // +0.5
        transmit_and_check(16'sh7FFF); // Maximum positive

        repeat (5) @(posedge clk);

        $display("--------------------------------");
        $display("ALL DAC CONTROLLER TESTS PASSED");
        $display("--------------------------------");

        $finish;

    end

    // -------------------------------------------------
    // Simulation timeout protection
    // -------------------------------------------------
    initial begin
        #100_000;
        $fatal(1, "ERROR: Simulation timeout");
    end

endmodule