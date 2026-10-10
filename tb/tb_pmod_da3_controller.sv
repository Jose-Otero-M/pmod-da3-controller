`timescale 1ns/1ps

module tb_pmod_da3_controller;
    // -------------------------------------------------
    // Testbench parameters
    // -------------------------------------------------
    localparam int CLK_PERIOD_NS = 10; // 100 MHz clock
    localparam int CLK_FREC_HZ   = 100_000_000;
    localparam int SCLK_FREQ_HZ  = 25_000_000;

    // -------------------------------------------------
    // DUT signals
    // -------------------------------------------------
    logic clk;
    logic rst;
    
    // Input sample
    logic signed [15:0] sample_in;
    logic               sample_valid;
    
    // Status
    logic               sample_ready;
    logic               sample_done;
    logic               busy;

    // Pmod DA3 interface
    logic               dac_cs_n;
    logic               dac_din;
    logic               dac_ldac_n;
    logic               dac_sclk;

    // -------------------------------------------------
    // Clock generation
    // -------------------------------------------------
    initial begin
        clk = 1'b0;
        forever  begin          //
            #(CLK_PERIOD_NS/2); // forever #(CLK_PERIOD_NS/2) clk = ~clk;
            clk = ~clk;         //
        end
    end

    // -------------------------------------------------
    // DUT instance
    // -------------------------------------------------
    pmod_da3_controller #(
        .CLK_FREC_HZ(CLK_FREC_HZ),
        .SCLK_FREQ_HZ(SCLK_FREQ_HZ)
    ) dut(
        .clk(clk),
        .rst(rst),
        .sample_in(sample_in),
        .sample_valid(sample_valid),
        .sample_ready(sample_ready),
        .sample_done(sample_done),
        .busy(busy),
        .dac_cs_n(dac_cs_n),
        .dac_din(dac_din),
        .dac_ldac_n(dac_ldac_n),
        .dac_sclk(dac_sclk)
    );


    // -------------------------------------------------
    // Tasks
    // -------------------------------------------------
    

    // -------------------------------------------------
    // Stimulus
    // -------------------------------------------------
    initial begin

    end

endmodule