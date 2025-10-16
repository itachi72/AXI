module AXI_Slave ( // Here the input is coming from the master
    input s_clk,
    input rst,
    /* ----- Address Given by master ------- */
    input [3:0] read_address, // 4-bit ready address
    input AR_VALID,
    output AR_READY,
    /* ----- Data being read from slave ------- */
    output [7:0] data_read,    // 8-bit data read
    output R_VALID,
    input R_READY // When master is ready to accept data
);
    reg [7:0] memory [0:15]; // 16 x 8-bit memory
    reg ar_ready_reg;
    reg r_valid_reg;

    assign AR_READY = ar_ready_reg;
    assign R_VALID = r_valid_reg;
    assign data_read = r_valid_reg ? read_data_reg : 0; // Show data on the data_read port only for the duration of R_VALID

    always@(posedge clk or rst) begin
        if (rst) begin
            ar_ready_reg <= 1'b0;
            // Initialize memory with some values (optional)
            memory[0] <= 8'h00; memory[1] <= 8'h11; memory[2] <= 8'h22; memory[3] <= 8'h33;
            memory[4] <= 8'h44; memory[5] <= 8'h55; memory[6] <= 8'h66; memory[7] <= 8'h77;
            memory[8] <= 8'h88; memory[9] <= 8'h99; memory[10] <= 8'hAA; memory[11] <= 8'hBB;
            memory[12] <= 8'hCC; memory[13] <= 8'hDD; memory[14] <= 8'hEE; memory[15] <= 8'hFF;
        end else begin
            /* Be ready for one cycle only when the master has asserted the AR_VALID */
            if (AR_VALID && !ar_ready_reg) begin
                ar_ready_reg <= 1'b1; // Indicate ready to accept address
            end else begin
                ar_ready_reg <= 1'b0; // Reset ready signal after one cycle
            end 

            /* This will happen in the next cycle after the above logic */
            /* main logic for accepting address and signalling data being read */
            /* Here again keep R_VALID high for one cycle only when the master is ready to accept data */
            if(AR_VALID && AR_READY) begin
                r_valid_reg <= 1'b1; // Indicate valid data is available
                read_data_reg <= memory[read_address]; // Capture the read address's data
            end else if(R_READY && r_valid_reg) begin
                r_valid_reg <= 1'b0; // Reset valid signal after master has accepted data
            end
        end
    end
endmodule
