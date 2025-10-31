/* This is the AXI master for AXI Lite */

module AXI_Master (
    input clk,
    input rst,
    /* ----- Address to be given to slave ------- */
    output reg [3:0] read_address, // 4-bit read address
    output reg AR_VALID,
    input AR_READY,
    /* ----- Data being read from slave ------- */
    input [7:0] data_read,    // 8-bit data read
    input R_VALID,
    output reg R_READY, // When master is ready to accept data
    /* ----- Address to be given to slave for write ------- */
    output reg [3:0] write_address, // 4-bit write address
    output reg AW_VALID,
    input AW_READY,
    /* ----- Data to be written to slave ------- */
    output reg [7:0] data_write,    // 8-bit data to write
    output reg W_VALID,
    input W_READY,
    /* ----- Write response from slave ------- */
    input B_VALID,
    output reg B_READY, // When master is ready to accept write response
    
    /* External interface for writing, reading data to and from slave */
    /* For now all are just a single tick, i.e AXI Lite like */
    input read,
    input write,
    input [3:0] address_to_read,
    input [3:0] address_to_write,
    input [7:0] data_to_write,
    output reg [7:0] data_being_read
);


    parameter reset_read = 6'b000000;
    parameter reset_write = 6'b000001;
    parameter address_read_state = 6'b000010;
    parameter data_read_state = 6'b000100;
    parameter address_for_write = 6'b001000;
    parameter data_for_write = 6'b010000;
    parameter write_response = 6'b100000;


    reg [5:0] state_read;
    reg [5:0] state_write;

    always@(posedge clk or rst) begin
        if (rst) begin
            /* Reset all signals */
            state_read <= reset_read;
            read_address <= 4'b0;
            AR_VALID <= 1'b0;
            R_READY <= 1'b0;
            data_being_read <= 8'b0;
        end else begin
            case(state_read)
                reset_read: begin
                    if (read) begin
                        state_read <= address_read_state;
                    end else begin
                        state_read <= reset_read;
                    end
                end
                address_read_state: begin
                    AR_VALID <= 1'b1; // Indicate valid read address
                    read_address <= address_to_read;
                    data_being_read <= 0; // Reset the read data before new read
                    state_read <= AR_READY ? data_read_state : address_read_state;
                end
                data_read_state: begin
                    AR_VALID <= 1'b0; // Reset after address is accepted
                    read_address <= 0; // Reset the read address after accepted
                    R_READY <= 1'b1; // Now suggest that ready to receive data
                    data_being_read <= data_read; // Capture the read data
                    if (read) begin
                        state_read <= address_read_state;
                    end begin
                        state_read <= reset_read;
                    end
                end
            endcase
        end
    end

    /* The write FSM */

    always@(posedge clk or rst) begin
        if (rst) begin
            /* Reset all signals */
            state_write <= reset_write;
            write_address <= 4'b0;
            AW_VALID <= 1'b0;
            data_write <= 8'b0;
            W_VALID <= 1'b0;
            B_READY <= 1'b0;
        end else begin
            case(state_write)
                reset_write: begin
                    AW_VALID <= 1'b0; // Resetting the address valid signal
                    W_VALID <= 1'b0; // Reset write valid
                    B_READY <= 1'b0; // Resetting the response ready signal
                    write_address <= 0; // Reset write address
                    data_write <= 0; // Reset data to write
                    if (write) begin
                        state_write <= address_for_write;
                    end else begin
                        state_write <= reset_write;
                    end
                end
                address_for_write: begin
                    AW_VALID <= 1'b1; // Indicate valid write address
                    B_READY <= 1'b0; // Resetting the response ready signal
                    write_address <= address_to_write; // send this address to AXI slave
                    data_write <= 0; // Reset the data to be written before new write
                    state_write <= AW_READY ? data_for_write : address_for_write;
                end
                data_for_write: begin
                    AW_VALID <= 1'b0; // Indicate valid write address
                    W_VALID <= 1'b1; // Now indicate valid data to write
                    write_address <= 0; // Reset the address after accepted
                    data_write <= data_to_write; // Capture the data to be written
                    state_write <= W_READY ? write_response : data_for_write;
                end
                write_response: begin
                    W_VALID <= 1'b0; // Now indicate valid data to write
                    data_write <= 0; // Reset the data to be written
                    B_READY <= 1'b1; // Suggesting that ready to accept the response now
                    if(B_VALID) begin
                        state_write <= write ? address_for_write : reset_write;
                    end else begin
                        state_write <= write_response;
                    end 
                end
            endcase
        end
    end
endmodule

