`timescale 1ns/1ps
`include "AXI_Master.v"
`include "AXI_Slave.v"

module axi_master_slave_tb();

    // Clock and reset signals
    reg clk;
    reg rst;

    // External interface signals for master
    reg read;
    reg write;
    reg [3:0] address_to_read;
    reg [3:0] address_to_write;
    reg [7:0] data_to_write;
    wire [7:0] data_being_read;

    // Interconnect signals between master and slave
    wire [3:0] read_address;
    wire AR_VALID;
    wire AR_READY;
    wire [7:0] data_read;
    wire R_VALID;
    wire R_READY;
    wire [3:0] write_address;
    wire AW_VALID;
    wire AW_READY;
    wire [7:0] data_write;
    wire W_VALID;
    wire W_READY;
    wire B_VALID;
    wire B_READY;

    // Instantiate AXI Master
    AXI_Master master (
        .clk(clk),
        .rst(rst),
        // Read address channel
        .read_address(read_address),
        .AR_VALID(AR_VALID),
        .AR_READY(AR_READY),
        // Read data channel
        .data_read(data_read),
        .R_VALID(R_VALID),
        .R_READY(R_READY),
        // Write address channel
        .write_address(write_address),
        .AW_VALID(AW_VALID),
        .AW_READY(AW_READY),
        // Write data channel
        .data_write(data_write),
        .W_VALID(W_VALID),
        .W_READY(W_READY),
        // Write response channel
        .B_VALID(B_VALID),
        .B_READY(B_READY),
        // External interface
        .read(read),
        .write(write),
        .address_to_read(address_to_read),
        .address_to_write(address_to_write),
        .data_to_write(data_to_write),
        .data_being_read(data_being_read)
    );

    // Instantiate AXI Slave
    AXI_Slave slave (
        .s_clk(clk),
        .rst(rst),
        // Read address channel
        .read_address(read_address),
        .AR_VALID(AR_VALID),
        .AR_READY(AR_READY),
        // Read data channel
        .data_read(data_read),
        .R_VALID(R_VALID),
        .R_READY(R_READY)
    );

    // Clock generation - 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        rst = 0;
        read = 0;
        write = 0;
        address_to_read = 0;
        address_to_write = 0;
        data_to_write = 0;

        // Reset sequence
        #100;
        rst = 1;
        
        // Test case 1: Write operation
        #100;
        rst = 0;
        #100;
        read = 1;
        address_to_read = 4'h5;
        #20;
        read = 0;
        write = 1;
        address_to_write = 4'h5;
        data_to_write = 8'hAA;
        #20;
        write = 0;

    #100;
        $finish;
    end

    // Debug: Monitor transactions
    initial begin
        $dumpfile("axi_master_slave_tb.vcd");
        $dumpvars(0, axi_master_slave_tb);
    end

endmodule