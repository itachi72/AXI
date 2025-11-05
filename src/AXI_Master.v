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
    input [3:0] BRESPONSE,
    output reg B_READY, // When master is ready to accept write response
    
    /* External interface for writing, reading data to and from slave */
    /* For now all are just a single tick, i.e AXI Lite like */
    input read,
    input write,
    input [3:0] address_to_read,
    input [3:0] address_to_write,
    input [7:0] data_to_write,
    output reg [7:0] data_being_read,
    output reg [3:0] response_code
);

    parameter IDLE_READ = 4'b0001;
    parameter IDLE_WRITE = 4'b0010;
    parameter data_read_state = 4'b0100;
    parameter write_response = 4'b1000;

    reg [3:0] state_read;
    reg [3:0] state_write;

    // AXI has 5 independent channels. So FSM not a good idea.
    // Each channel should be handled independently.


    // The send address channel
    // Signals: read_address, AR_VALID
    always@(posedge clk) begin
        if (rst) begin
            /* Reset all signals */
            read_address <= 4'b0;
            AR_VALID <= 1'b0;
        end else begin
            if (read) begin
                AR_VALID <= 1'b1; // Indicate valid read address
                read_address <= address_to_read;
            end else begin
                AR_VALID <= AR_READY ? 1'b0 : AR_VALID; // Keep the same value while AR_READY has not come yet
                read_address <= AR_READY ? 0 : read_address;
            end
        end
    end

    // The data read channel
    // Signals: R_READY, data_being_read
    always@(posedge clk) begin
        if (rst) begin
            R_READY <= 1'b0;
            data_being_read <= 8'b0;
        end else begin
            if(R_VALID) begin
                R_READY <= 1'b0; // Reset ready after data is accepted
                data_being_read <= data_read; // Capture the read data
            end else begin
                R_READY <= 1'b1; // Always ready to read some data
                data_being_read <= 0;
            end
        end
    end

    // The write address and write data (two channels handled together)
    // Signals: write_address, AW_VALID, data_write, W_VALID
    always@(posedge clk) begin
        if (rst) begin
            /* Reset all signals */
            AW_VALID <= 1'b0;
            W_VALID <= 1'b0;
            write_address <= 0;
            data_write <= 0;
        end else begin
            if (write) begin
                /* Send address and data along with AW_VALID and W_VALID to slave */
                AW_VALID <= 1'b1; // Indicate valid write address
                write_address <= address_to_write; // send this address to AXI slave
                W_VALID <= 1'b1; // Now indicate valid data to write
                data_write <= data_to_write; // Capture the data to be written
            end else begin
                AW_VALID <= AW_READY ? 1'b0 : AW_VALID; // Keep the same value while AW_READY has not come yet
                write_address <= AW_READY ? 0 : write_address;
                W_VALID <= W_READY ? 1'b0 : W_VALID; // Keep the same value while W_READY has not come yet
                data_write <= W_READY ? 0 : data_write;
            end
        end
    end

    // The write response channel. Active only if write is done
    // Signals: B_READY, BRESPONSE
    always@(posedge clk) begin
        if (rst) begin
            /* Reset all signals */
            B_READY <= 1'b1;
            response_code <= 4'b0;
        end else begin
            if(write) begin
                // If continuous writes happen, keep B_READY high (reset value is 1 so taken care of)
                if(B_VALID) begin // If previous transation response is there
                    response_code <= BRESPONSE; // Capture the response code
                end else begin
                    response_code <= 0; // Suggesting that ready to accept the response now
                end
            end else begin
                if(B_VALID) begin // If previous transation response is there
                    B_READY <= 1'b0; // Now last write in a way is done, so accept the response once
                    response_code <= BRESPONSE; // Capture the response code// Now last write in a way is done, so accept the response once
                end else begin
                    B_READY <= 1; // Keep B_READY high till it doesnt get any response
                    response_code <= 0; // Clear response after accepted
                end
            end
        end
    end
endmodule

