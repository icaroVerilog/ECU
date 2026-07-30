//==============================================================================
// Modulo: crankshaft_position
//
// Descricao:
// Mantem a posicao discreta da roda fonica depois que a falha dos dentes e
// identificada.
//
// missing_tooth representa a borda do primeiro dente fisico depois da falha.
// Nesse evento, tooth_number e realinhado para zero. Nos demais dentes, a
// contagem avanca de zero ate PHYSICAL_TEETH - 1.
//
// A conversao da posicao discreta para angulo continuo pertence ao modulo
// angle_interpolator.
//==============================================================================

module crankshaft_position #(
    parameter integer TOTAL_TEETH    = 60,
    parameter integer PHYSICAL_TEETH = 58
)(
    input  wire clk,
    input  wire rst,
    input  wire tooth_rise,
    input  wire sync,
    input  wire missing_tooth,

    output reg [$clog2(PHYSICAL_TEETH)-1:0] tooth_number,
    output reg                              position_valid
);

    // Indica que a referencia da roda ja foi encontrada e a posicao e valida.
    reg sync_active;

    always @(posedge clk) begin
        if (rst) begin
            tooth_number   <= 0;
            position_valid <= 1'b0;
            sync_active    <= 1'b0;
        end
        else begin
            // Mantem o sincronismo ativo depois que a falha e detectada.
            if (sync) begin
                sync_active <= 1'b1;
            end

            // O primeiro dente depois da falha define o inicio da nova volta.
            if (missing_tooth) begin
                tooth_number   <= 0;
                position_valid <= 1'b1;
                sync_active    <= 1'b1;
            end
            else if (sync_active) begin
                // A posicao permanece valida enquanto o sistema esta sincronizado.
                position_valid <= 1'b1;

                if (tooth_rise) begin
                    // Avanca para o proximo dente fisico enquanto nao atingir o limite.
                    if (tooth_number < PHYSICAL_TEETH - 1) begin
                        tooth_number <= tooth_number + 1'b1;
                    end
                    else begin
                        // Evita ultrapassar a quantidade de dentes fisicos da roda.
                        tooth_number <= 0;
                    end
                end
            end
            else begin
                // Sem sincronismo, nenhuma posicao deve ser considerada valida.
                tooth_number   <= 0;
                position_valid <= 1'b0;
            end
        end
    end
endmodule