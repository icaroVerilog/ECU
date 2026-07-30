//==============================================================================
// Modulo: period_counter
//
// Descricao:
// Mede, em ciclos de clock, o intervalo entre duas bordas de subida
// consecutivas do sensor CKP.
//
// Alem do ultimo periodo concluido, o modulo expoe continuamente o tempo
// decorrido desde o ultimo dente. Essa segunda informacao e utilizada pelo
// angle_interpolator para estimar a posicao angular entre dentes.
//
// A primeira borda apos o reset apenas estabelece a referencia temporal. Uma
// medicao valida somente e publicada a partir da segunda borda.
//
// Medicao do periodo:
//
// tooth_period = time_since_tooth + 1
//
// A soma de um inclui o ciclo da borda atual no intervalo medido entre as
// duas bordas consecutivas.
//==============================================================================

module period_counter (
    input  wire        clk,
    input  wire        rst,
    input  wire        tooth_rise,

    output reg  [31:0] tooth_period,
    output reg         period_valid,
    output reg  [31:0] time_since_tooth
);

    // Indica que uma primeira borda ja foi recebida e existe uma referencia.
    reg has_previous_tooth;

    always @(posedge clk) begin
        if (rst) begin
            tooth_period       <= 32'd0;
            period_valid       <= 1'b0;
            time_since_tooth   <= 32'd0;
            has_previous_tooth <= 1'b0;
        end
        else begin
            // period_valid permanece ativo por somente um ciclo de clock.
            period_valid <= 1'b0;

            if (tooth_rise) begin
                if (has_previous_tooth) begin
                    // Soma um ao contador para incluir o ciclo da nova borda.
                    if (time_since_tooth == 32'hFFFFFFFF) begin
                        // Mantem o periodo no valor maximo quando o contador saturou.
                        tooth_period <= 32'hFFFFFFFF;
                    end
                    else begin
                        tooth_period <= time_since_tooth + 32'd1;
                    end

                    // Indica que um novo periodo completo foi publicado.
                    period_valid <= 1'b1;
                end
                else begin
                    // A primeira borda apenas inicia a referencia temporal.
                    has_previous_tooth <= 1'b1;
                end

                // Reinicia a medicao do tempo para o proximo dente.
                time_since_tooth <= 32'd0;
            end
            else if (has_previous_tooth) begin
                // Incrementa o tempo decorrido enquanto aguarda o proximo dente.
                if (time_since_tooth != 32'hFFFFFFFF) begin
                    time_since_tooth <= time_since_tooth + 32'd1;
                end
            end
        end
    end

endmodule