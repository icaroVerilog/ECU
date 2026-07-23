// module injector_controller #(
//     parameter integer C_TIMER_WIDTH = 32
// )(
//     input wire clk,
//     input wire rst,
//     input wire injection_request,
//     input wire enable,
//     input wire [31:0] open_time, // Tempo de abertura em ns

//     output wire injector0_out,
//     output wire injector1_out,
//     output wire injector2_out,
//     output wire injector3_out,
// );

//     reg [1:0] injector_pair_start; 

//     injector_timer #(
//         .FREQ_HZ(50000000)
//     ) injector0 (
//         .clk(clk),
//         .rst(rst),
//         .open_time(open_time),
//         .start(injector_pair_start[0]),
//         .out(injector0_out),
//         .executing(executing)
//     );

//     injector_timer #(
//         .FREQ_HZ(50000000)
//     ) injector1 (
//         .clk(clk),
//         .rst(rst),
//         .open_time(open_time),
//         .start(injector_pair_start[1]),
//         .out(injector1_out),
//         .executing(executing)
//     );

//     injector_timer #(
//         .FREQ_HZ(50000000)
//     ) injector2 (
//         .clk(clk),
//         .rst(rst),
//         .open_time(open_time),
//         .start(injector_pair_start[1]),
//         .out(injector2_out),
//         .executing(executing)
//     );

//     injector_timer #(
//         .FREQ_HZ(50000000)
//     ) injector3 (
//         .clk(clk),
//         .rst(rst),
//         .open_time(open_time),
//         .start(injector_pair_start[0]),
//         .out(injector3_out),
//         .executing(executing)
//     );


//     always @(posedge clk) begin
//         if (rst) begin
//             start <= 1'b0;
//             injector_pair_start <= 2'b00;
//         end else begin
//             // Lógica para iniciar o pulso de injeção
//             start <= 1'b1; // Exemplo: sempre inicia o pulso
//         end
//     end
    
// endmodule



// module injector_controller #(
//     parameter integer C_TIMER_WIDTH = 32
// )(
//     input wire clk,
//     input wire rst,
//     input wire injection_request,
//     input wire enable,
//     input wire [31:0] open_time,

//     output wire injector0_out,
//     output wire injector1_out,
//     output wire injector2_out,
//     output wire injector3_out
// );

//     reg [1:0] injector_pair_start;
//     reg injection_request_prev;

//     wire executing0;
//     wire executing1;
//     wire executing2;
//     wire executing3;

//     injector_timer #(
//         .FREQ_HZ(50000000)
//     ) injector0 (
//         .clk(clk),
//         .reset(rst),
//         .open_time(open_time),
//         .start(injector_pair_start[0]),
//         .out(injector0_out),
//         .executing(executing0)
//     );

//     injector_timer #(
//         .FREQ_HZ(50000000)
//     ) injector1 (
//         .clk(clk),
//         .reset(rst),
//         .open_time(open_time),
//         .start(injector_pair_start[1]),
//         .out(injector1_out),
//         .executing(executing1)
//     );

//     injector_timer #(
//         .FREQ_HZ(50000000)
//     ) injector2 (
//         .clk(clk),
//         .reset(rst),
//         .open_time(open_time),
//         .start(injector_pair_start[1]),
//         .out(injector2_out),
//         .executing(executing2)
//     );

//     injector_timer #(
//         .FREQ_HZ(50000000)
//     ) injector3 (
//         .clk(clk),
//         .reset(rst),
//         .open_time(open_time),
//         .start(injector_pair_start[0]),
//         .out(injector3_out),
//         .executing(executing3)
//     );

//     always @(posedge clk) begin
//         if (rst) begin
//             injector_pair_start <= 2'b00;
//             injection_request_prev <= 1'b0;
//         end
//         else begin
//             injection_request_prev <= injection_request;

//             // pulso de start dura apenas um ciclo de clock
//             injector_pair_start <= 2'b00;

//             if (enable) begin
//                 if (injection_request && !injection_request_prev) begin

//                     // dispara par 0-3
//                     injector_pair_start[0] <= 1'b1;

//                 end
//             end
//         end
//     end
// endmodule


module injector_controller #(
    parameter integer C_TIMER_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire injection_request,
    input wire enable,
    input wire [31:0] open_time,

    output wire injector0_out,
    output wire injector1_out,
    output wire injector2_out,
    output wire injector3_out
);

    reg [1:0] injector_pair_start;
    reg injection_request_prev;
    reg pair_select;

    wire executing0;
    wire executing1;
    wire executing2;
    wire executing3;

    wire executing_pair0;
    wire executing_pair1;

    assign executing_pair0 = executing0 | executing3;
    assign executing_pair1 = executing1 | executing2;

    injector_timer #(
        .FREQ_HZ(50000000)
    ) injector0 (
        .clk(clk),
        .rst(rst),
        .open_time(open_time),
        .start(injector_pair_start[0]),
        .out(injector0_out),
        .executing(executing0)
    );

    injector_timer #(
        .FREQ_HZ(50000000)
    ) injector1 (
        .clk(clk),
        .rst(rst),
        .open_time(open_time),
        .start(injector_pair_start[1]),
        .out(injector1_out),
        .executing(executing1)
    );

    injector_timer #(
        .FREQ_HZ(50000000)
    ) injector2 (
        .clk(clk),
        .rst(rst),
        .open_time(open_time),
        .start(injector_pair_start[1]),
        .out(injector2_out),
        .executing(executing2)
    );

    injector_timer #(
        .FREQ_HZ(50000000)
    ) injector3 (
        .clk(clk),
        .rst(rst),
        .open_time(open_time),
        .start(injector_pair_start[0]),
        .out(injector3_out),
        .executing(executing3)
    );

    always @(posedge clk) begin
        if (rst) begin
            injector_pair_start <= 2'b00;
            injection_request_prev <= 1'b0;
            pair_select <= 1'b0;
        end
        else begin
            injection_request_prev <= injection_request;

            // start dura somente um ciclo
            injector_pair_start <= 2'b00;

            if (enable) begin

                // detecta borda de subida do pedido
                if (injection_request && !injection_request_prev) begin

                    // seleciona par 0
                    if (!pair_select && !executing_pair0) begin
                        injector_pair_start[0] <= 1'b1;
                        pair_select <= 1'b1;
                    end

                    // seleciona par 1
                    else if (pair_select && !executing_pair1) begin
                        injector_pair_start[1] <= 1'b1;
                        pair_select <= 1'b0;
                    end

                end
            end
        end
    end
endmodule