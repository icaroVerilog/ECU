module injector_timer #(
    parameter FREQ_HZ = 50000000 // Clock de 50 MHz (1 ciclo = 20 ns)
)(
    input  wire clk,
    input  wire rst,
    input  wire [31:0] open_time, // Tempo de abertura em ns
    input  wire start,            // Comando para iniciar o pulso
    output reg out,
    output reg executing
);

    /* calculando a quantidade de ciclos necessários para o pulso durar a quantidade de tempo open_time */
    localparam [31:0] CLOCK_CYCLE_TIME_NS = 64'd1000000000 / FREQ_HZ; // Tempo de um ciclo de clock em ns

    // Conversão dinâmica do tempo de abertura para ciclos
    wire [31:0] open_time_cycles;

    assign open_time_cycles = open_time / CLOCK_CYCLE_TIME_NS;

    reg [63:0] counter;
    reg busy;
    reg start_prev;

    initial begin
        $display("FREQ_HZ              = %0d Hz", FREQ_HZ);
        $display("CLOCK_CYCLE_TIME_NS  = %0d ns", CLOCK_CYCLE_TIME_NS);
        $display("open_time            = %0d ns", open_time);
        $display("open_time_cycles     = %0d cycles", open_time_cycles);
    end

    always @(posedge clk) begin
        if (rst) begin
            counter    <= 64'd0;
            out        <= 1'b0;
            busy       <= 1'b0;
            executing  <= 1'b0;
            start_prev <= 1'b0;
        end
        else begin
            // Guarda o estado anterior do start para detectar borda de subida
            start_prev <= start;

            // Inicia um novo pulso somente quando start muda de 0 para 1
            if (start && !start_prev && !busy) begin
                counter   <= 64'd0;
                out       <= 1'b1;
                busy      <= 1'b1;
                executing <= 1'b1;
            end
            // Mantém o pulso ativo enquanto conta o tempo de abertura
            else if (busy) begin
                if (counter < open_time_cycles - 1) begin
                    counter <= counter + 1'b1;
                    out     <= 1'b1;
                end
                else begin
                    counter   <= 64'd0;
                    out       <= 1'b0;
                    busy      <= 1'b0;
                    executing <= 1'b0;
                end
            end
            // Estado parado aguardando novo comando
            else begin
                counter <= 64'd0;
                out     <= 1'b0;
            end
        end
    end
endmodule