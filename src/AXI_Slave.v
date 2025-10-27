/* This is AXI slave module for AXI Lite */

module AXI_Slave ( // Here the input is coming from the master
    input s_clk,
    input rst,
    /* ----- Address Given by master ------- */
    input [3:0] read_address, // 4-bit ready address
    input AR_VALID,
    output reg AR_READY,
    /* ----- Data being read from slave ------- */
    output reg [7:0] data_read,    // 8-bit data read
    output reg R_VALID,
    input R_READY, // When master is ready to accept data

    /* ----- Address Given by master for write ------- */
    input [3:0] write_address, // 4-bit write address
    input AW_VALID,
    output reg AW_READY,
    /* ----- Data to be written to slave ------- */
    input [7:0] write_data,    // 8-bit data to write
    input W_VALID,
    output reg W_READY,
    /* ----- Write response to master ------- */
    output reg B_VALID,
    input B_READY // When master is ready to accept write response
);
    reg [7:0] memory [0:15]; // 16 x 8-bit memory
    reg ar_ready_reg;
    reg r_valid_reg;
    reg [3:0] current_read_address;
    reg [3:0] current_write_address;

    always@(posedge s_clk or rst) begin
        if (rst) begin
            ar_ready_reg <= 1'b0;
            // Initialize memory with some values (optional)
            memory[0] <= 8'h00; memory[1] <= 8'h11; memory[2] <= 8'h22; memory[3] <= 8'h33;
            memory[4] <= 8'h44; memory[5] <= 8'h55; memory[6] <= 8'h66; memory[7] <= 8'h77;
            memory[8] <= 8'h88; memory[9] <= 8'h99; memory[10] <= 8'hAA; memory[11] <= 8'hBB;
            memory[12] <= 8'hCC; memory[13] <= 8'hDD; memory[14] <= 8'hEE; memory[15] <= 8'hFF;
        end else begin
            /* Address sending and data receiving logic */
            /* Be ready for one cycle only when the master has asserted the AR_VALID */
            if (AR_VALID && !AR_READY) begin
                AR_READY <= 1'b1; // Indicate ready to accept address
                current_read_address <= read_address; // Capture the read address
            end else begin
                AR_READY <= 1'b0; // Reset ready signal after one cycle
            end 

            /* This will happen in the next cycle after the above logic */
            /* main logic for accepting address and signalling data being read */
            /* Here again keep R_VALID high for one cycle only when the master is ready to accept data */
            if(AR_VALID && AR_READY && !R_VALID) begin
                R_VALID <= 1'b1; // Indicate valid data is available
                data_read <= memory[current_read_address]; // Capture the read address's data
            end else if(R_READY) begin // Master has accepted the data
                R_VALID <= 1'b0; // Reset valid signal after master has accepted data
                data_read <= 0; // Capture the read address's data
            end

            /* Address sending and data writing logic */
            if(AW_VALID && !AW_READY) begin
                AW_READY <= 1'b1; // Indicate ready to accept address
                current_write_address <= write_address; // Capture the write address
            end else begin
                AW_READY <= 1'b0; // Reset ready signal after one cycle
            end

            if(W_VALID && !W_READY) begin
                W_READY <= 1'b1; // Indicate valid data is available
                memory[current_write_address] <= write_data; // Write data to the captured address
            end else begin // Master has accepted the data
                W_READY <= 1'b0; // Reset valid signal after master has accepted data
            end

            /* Data writing done */

            /* Response logic */
            if(W_VALID && W_READY) begin
                B_VALID <= 1'b1; // Indicate response is valid
            end else begin
                B_VALID <= 1'b0; // Reset response valid signal after one cycle
            end
        end
    end
endmodule
