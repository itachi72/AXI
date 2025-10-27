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

    always@(posedge clk or rst) begin
        if (rst) begin
            /* Reset all signals */
            read_address <= 4'b0;
            AR_VALID <= 1'b0;
            R_READY <= 1'b0;
            write_address <= 4'b0;
            AW_VALID <= 1'b0;
            data_write <= 8'b0;
            W_VALID <= 1'b0;
            B_READY <= 1'b0;
            data_being_read <= 8'b0;
        end else begin
            /* Send address for read, and then read the data */
            if (read) begin
                read_address <= address_to_read; // address sent to AXI slave
                AR_VALID <= 1'b1; // Indicate valid read address
                if (AR_READY && AR_VALID) begin // Slave should set AR_READY
                    AR_VALID <= 1'b0; // Reset after address is accepted
                    R_READY <= 1'b1; // Once address transaction is done, now sugges that ready to receive data
                end
                if (R_VALID && R_READY) begin // If slave has valid data to send, then accept it and reset R_READY
                    data_being_read <= data_read; // Capture the read data
                    R_READY <= 1'b0; // Reset after data is accepted
                end
            end

            /* Send address for write and then write the data */
            if (write) begin
                write_address <= address_to_write; // send this address to AXI slave
                AW_VALID <= 1'b1; // Indicate valid write address
                if (AW_READY && AW_VALID) begin
                    AW_VALID <= 1'b0; // Reset after address is accepted
                    W_VALID <= 1'b1; // Now indicate valid data to write
                    data_write <= data_to_write; // Capture the data to be written
                end
                if (W_READY && W_VALID) begin
                    W_VALID <= 1'b0; // Reset after data is accepted
                    B_READY <= 1'b1; // Suggesting that ready to accept the response now */
                end

                /* If slave gives valid response, accpet it and reset B_READY */
                if (B_VALID && B_READY) begin
                    B_READY <= 1'b0; // Reset after response is accepted
                end
            end
        end
    end
endmodule

