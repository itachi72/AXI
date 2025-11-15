/* This is AXI slave module for AXI Lite */

`include "axi_params.vh"

module AXI_Slave ( // Here the input is coming from the master
    input s_clk,
    input rst,
    /* ----- Address Given by master ------- */
    input [`ADDR_RANGE] read_address, // read address
    input AR_VALID,
    output reg AR_READY,
    /* ----- Data being read from slave ------- */
    output reg [`DATA_RANGE] data_read,    // data read
    output reg R_VALID,
    input R_READY, // When master is ready to accept data

    /* ----- Address Given by master for write ------- */
    input [`ADDR_RANGE] write_address, // write address
    input AW_VALID,
    output reg AW_READY,
    /* ----- Data to be written to slave ------- */
    input [`DATA_RANGE] write_data,    // data to write
    input W_VALID,
    output reg W_READY,
    /* ----- Write response to master ------- */
    output reg B_VALID,
    output reg [3:0] BRESPONSE,
    input B_READY // When master is ready to accept write response
);

    reg [`DATA_RANGE] memory [0:((1 << `ADDR_WIDTH) - 1)]; // Memory with size determined by address width

    /* Handling the read address and read data channels together */
    /* Takes only two clock cycles to read data from slave */
    /* Signals: read_address, AR_VALID, data_read, R_VALID */

    always@(posedge s_clk) begin
        if (rst) begin
            R_VALID <= 1'b0;
            AR_READY <= 1'b1;
            data_read <= 8'd0;
        end else begin
            if(AR_VALID) begin
              AR_READY <= 1'b0; // Reset after address is accepted
              R_VALID <= 1'b1; // Now suggest that valid data is available
              data_read <= memory[read_address]; // directly use address to read from memory
            end else begin
              AR_READY <= 1'b1;
              R_VALID <= 1'b0; // Clear previous valid
              data_read <= 0; // Clear previous data
            end
        end
    end

    /* Handling the address read and data read states together */
    /* This will also take only two cycles */

    always@(posedge s_clk) begin
        if (rst) begin
            AW_READY <= 1'b1; // Always ready to accept address
            W_READY <= 1'b1;  // Always ready to accept data
            // Initialize memory with some values (optional)
            memory[0] <= 8'h00; memory[1] <= 8'h11; memory[2] <= 8'h22; memory[3] <= 8'h33;
            memory[4] <= 8'h44; memory[5] <= 8'h55; memory[6] <= 8'h66; memory[7] <= 8'h77;
            memory[8] <= 8'h88; memory[9] <= 8'h99; memory[10] <= 8'hAA; memory[11] <= 8'hBB;
            memory[12] <= 8'hCC; memory[13] <= 8'hDD; memory[14] <= 8'hEE; memory[15] <= 8'hFF;
        end else begin
                if(AW_VALID && W_VALID) begin // If both data and address are valid in same cycle
                    AW_READY <= 1'b0; // Indicate ready to accept address
                    W_READY <= 1'b0; // Indicate ready to accept data
                    memory[write_address] <= write_data; // Write the data to memory
                end else begin  // Wait for valid address
                    AW_READY <= 1'b1; // Indicate ready to accept address
                    W_READY <= 1'b1; // Indicate ready to accept data
                end
        end
    end

    /* The response channel for write */

    always@(posedge s_clk or rst) begin
        if (rst) begin
            B_VALID <= 1'b0;
        end else begin
            if(!AW_READY && !W_READY) begin // If both address and data were accepted
                B_VALID <= 1'b1; // Now suggest that write response is valid
                BRESPONSE <= 4'd3; // OKAY response
            end else if(B_READY) begin
                B_VALID <= 1'b0; // Clear write response after accepted
            end
        end
    end

endmodule
