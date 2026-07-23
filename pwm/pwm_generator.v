module pwm_generator #(
    parameter FREQ_HZ        = 50_000_000,
    parameter INITIAL_WIDTH  = 20,
    parameter INITIAL_PERIOD = 100,
    parameter STEP_CYCLES    = 1
)(
    input  wire clk,
    input  wire reset,

    output reg  out
);

    localparam [63:0] INIT_WIDTH_CYCLES =
        (64'd1 * FREQ_HZ * INITIAL_WIDTH) / 64'd1_000_000_000;

    localparam [63:0] INIT_PERIOD_CYCLES =
        (64'd1 * FREQ_HZ * INITIAL_PERIOD) / 64'd1_000_000_000;

    reg [63:0] counter;

    initial begin
        $display("INIT_WIDTH_CYCLES  = %0d", INIT_WIDTH_CYCLES);
        $display("INIT_PERIOD_CYCLES = %0d", INIT_PERIOD_CYCLES);
    end

    always @(posedge clk) begin
        if (reset) begin
            counter <= 64'd0;
            out     <= 1'b0;
        end
        else begin
            // Contador do período
            if (counter == (INIT_PERIOD_CYCLES - 1))
                counter <= 64'd0;
            else
                counter <= counter + 64'd1;

            // Geração do pulso
            if (counter < INIT_WIDTH_CYCLES)
                out <= 1'b1;
            else
                out <= 1'b0;
        end
    end

endmodule

// module gerador_pulso_total_controle #(
//     parameter FREQ_HZ       = 50000000, // Clock de 50 MHz (1 ciclo = 20 ns)
//     parameter INICIAL_LARG  = 20,       // Largura inicial em ns (20 ns = 1 ciclo)
//     parameter INICIAL_PER   = 100,      // Período inicial em ns (100 ns = 5 ciclos)
//     parameter PASSO_CICLOS  = 1         // Quantos ciclos de clock mudam a cada clique
// )(
//     input  wire clk,
//     input  wire reset,                  // Reset Síncrono
//     input  wire trigger,                // Se for 1: oscila o PWM. Se for 0: morre em 0.
    
//     // Botões para controlar o tempo em '1' (Largura)
//     input  wire btn_larg_inc,           
//     input  wire btn_larg_dec,           
    
//     // Botões para controlar o intervalo total (Período)
//     input  wire btn_per_inc,            
//     input  wire btn_per_dec,            
    
//     output reg  saida
// );

//     // Converte os valores iniciais de parâmetros (ns) para ciclos de clock na compilação
//     localparam [31:0] INIT_LARG_CICLOS = ( (FREQ_HZ * INICIAL_LARG) / 1000000000 );
//     localparam [31:0] INIT_PER_CICLOS  = ( (FREQ_HZ * INICIAL_PER) / 1000000000 );

//     // Registradores dinâmicos que guardam os limites de tempo atuais (alterados por botões)
//     reg [31:0] limite_largura; 
//     reg [31:0] limite_periodo; 

//     reg [31:0] contador;

//     // Registradores para detectar a borda de subida (clique único) de cada botão
//     reg larg_inc_r, larg_dec_r, per_inc_r, per_dec_r;

//     always @(posedge clk) begin
//         if (reset) begin
//             contador       <= 32'd0;
//             saida          <= 1'b0;
//             // Carrega os tempos iniciais de largura e período
//             limite_largura <= (INIT_LARG_CICLOS == 0) ? 32'd1 : INIT_LARG_CICLOS;
//             limite_periodo <= (INIT_PER_CICLOS == 0) ? 32'd2 : INIT_PER_CICLOS;
//             // Limpa registradores de borda
//             larg_inc_r     <= 1'b0; larg_dec_r <= 1'b0;
//             per_inc_r      <= 1'b0; per_dec_r  <= 1'b0;
//         end else begin
            
//             // 1. Amostragem dos botões para pegar apenas o instante do clique (borda)
//             larg_inc_r <= btn_larg_inc; larg_dec_r <= btn_larg_dec;
//             per_inc_r  <= btn_per_inc;  per_dec_r  <= btn_per_dec;

//             // 2. CONTROLE DA LARGURA (Tempo em '1')
//             if (btn_larg_inc && !larg_inc_r) begin
//                 // Não deixa a largura ficar maior ou igual ao período total
//                 if ((limite_largura + PASSO_CICLOS) < limite_periodo)
//                     limite_largura <= limite_largura + PASSO_CICLOS;
//             end
//             else if (btn_larg_dec && !larg_dec_r) begin
//                 // Garante largura mínima de pelo menos 1 ciclo de clock
//                 if (limite_largura > PASSO_CICLOS)
//                     limite_largura <= limite_largura - PASSO_CICLOS;
//             end

//             // 3. CONTROLE DO PERÍODO (Intervalo total de subida)
//             if (btn_per_inc && !per_inc_r) begin
//                 limite_periodo <= limite_periodo + PASSO_CICLOS;
//             end
//             else if (btn_per_dec && !per_dec_r) begin
//                 // Não deixa o período encolher a ponto de esmagar a largura configurada
//                 if (limite_periodo > (limite_largura + PASSO_CICLOS))
//                     limite_periodo <= limite_periodo - PASSO_CICLOS;
//             end

//             // 4. LÓGICA DE GERAÇÃO DA ONDA (Se o trigger estiver ativo)
//             if (trigger) begin
//                 // O contador dita o compasso do período total
//                 if (contador < (limite_periodo - 1)) begin
//                     contador <= contador + 1'b1;
//                 end else begin
//                     contador <= 32'd0; // Bateu o tempo total, reinicia o ciclo e sobe a onda
//                 end

//                 // Define a saída olhando puramente as regras de tempo em '1'
//                 if (contador < limite_largura) begin
//                     saida <= 1'b1; // Janela de tempo ativo
//                 end else begin
//                     saida <= 1'b0; // Janela de espera para a próxima subida
//                 end
//             end else begin
//                 // Se desligar o trigger, zera tudo imediatamente
//                 contador <= 32'd0;
//                 saida    <= 1'b0;
//             end

//         end
//     end

// endmodule

