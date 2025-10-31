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

    parameter reset_read = 6'b000000;
    parameter reset_write = 6'b000001;
    parameter address_read = 6'b000010;
    parameter data_read_state = 6'b000100;
    parameter address_for_write = 6'b001000;
    parameter data_for_write = 6'b010000;
    parameter write_response = 6'b100000;

    reg [5:0] state_read;
    reg [5:0] state_write;
    reg [7:0] memory [0:15]; // 16 x 8-bit memory
    reg r_valid_reg;
    reg [3:0] current_read_address;
    reg [3:0] current_write_address;

    always@(posedge s_clk or rst) begin
        if (rst) begin
            state_read <= address_read;
            R_VALID <= 1'b0;
            AR_READY <= 1'b0;
            data_read <= 8'd0;
        end else begin
            case(state_read)
                address_read: begin
                    data_read <= 0; // Clear previous data
                    if(AR_VALID) begin
                      AR_READY <= 1'b1; // Indicate ready to accept address
                      current_read_address <= read_address; // Capture the read address
                      state_read <= data_read_state;
                    end else begin
                      state_read <= address_read;
                    end
                end
                data_read_state: begin
                    AR_READY <= 1'b0; // Reset after address is accepted
                    R_VALID <= 1'b1; // Now suggest that valid data is available
                    current_read_address <= 0; // Reset the read address after accepted
                    data_read <= memory[current_read_address];
                    state_read <= R_READY ? address_read : data_read_state;
                end
            endcase
        end
    end

    /* The write FSM */

    always@(posedge s_clk or rst) begin
        if (rst) begin
            state_write <= address_for_write;
            AW_READY <= 1'b0;
            W_READY <= 1'b0;
            B_VALID <= 1'b0;
            // Initialize memory with some values (optional)
            memory[0] <= 8'h00; memory[1] <= 8'h11; memory[2] <= 8'h22; memory[3] <= 8'h33;
            memory[4] <= 8'h44; memory[5] <= 8'h55; memory[6] <= 8'h66; memory[7] <= 8'h77;
            memory[8] <= 8'h88; memory[9] <= 8'h99; memory[10] <= 8'hAA; memory[11] <= 8'hBB;
            memory[12] <= 8'hCC; memory[13] <= 8'hDD; memory[14] <= 8'hEE; memory[15] <= 8'hFF;
        end else begin
            case(state_write)
                address_for_write: begin
                    B_VALID <= 1'b0; // Reset write response valid at new write address
                    if(AW_VALID) begin
                        AW_READY <= 1'b1; // Indicate ready to accept address
                        current_write_address <= write_address; // Capture the write address
                        state_write <= data_for_write;
                    end else begin
                        state_write <= address_for_write;
                    end
                end
                data_for_write: begin
                    AW_READY <= 1'b0; // Reset after address is accepted
                    W_READY <= 1'b1; // Now suggest that ready to accept data
                    if(W_VALID) begin
                        memory[current_write_address] <= write_data; // Write the data to memory
                        state_write <= write_response;
                    end else 
                        state_write <= data_for_write;
                end
                write_response: begin
                    W_READY <= 1'b0; // Reset after data is accepted
                    B_VALID <= 1'b1; // Now suggest that write response is valid
                    current_write_address <= 0; // Reset the write address after accepted
                    state_write <= B_READY ? address_for_write : write_response;
                end
            endcase
        end
    end
endmodule
