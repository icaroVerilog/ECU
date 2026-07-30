//==============================================================================
// Modulo: rpm_estimator
//
// Descricao:
// Calcula a rotacao do motor a partir do periodo normal entre duas posicoes
// consecutivas da roda fonica.
//
// Formula:
//
// RPM = (60 * CLK_FREQ) / (tooth_period * TEETH)
//
// Onde:
//
// 60           = quantidade de segundos em um minuto
// CLK_FREQ     = frequencia do clock em hertz
// tooth_period = periodo normal entre dentes em ciclos de clock
// TEETH        = quantidade total de posicoes angulares da roda
//
// Para uma roda 60-2, TEETH deve ser 60. Embora existam 58 dentes fisicos, a
// distancia angular entre dentes normais continua sendo 360 / 60 = 6 graus.
//
// O intervalo triplo da falha nao deve ser enviado a este modulo. Deve ser
// utilizado o periodo normal filtrado pelo missing_tooth_detector.
//==============================================================================

module rpm_estimator #(
    parameter integer CLK_FREQ = 50000000,
    parameter integer TEETH    = 60
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] tooth_period,
    input  wire        tooth_period_valid,

    output reg  [31:0] rpm,
    output reg         rpm_valid
);

    // Calcula o numerador fixo da formula: 60 segundos vezes o clock.
    localparam [63:0] RPM_NUMERATOR = 64'd60 * CLK_FREQ;

    wire [63:0] denominator;

    // Calcula quantos ciclos de clock correspondem a uma volta completa.
    assign denominator = {32'd0, tooth_period} * TEETH;

    always @(posedge clk) begin
        if (rst) begin
            rpm       <= 32'd0;
            rpm_valid <= 1'b0;
        end
        else begin
            // rpm_valid permanece ativo por somente um ciclo de clock.
            rpm_valid <= 1'b0;

            if (tooth_period_valid && (denominator != 64'd0)) begin
                // Divide o numerador fixo pelo tempo medido de uma volta.
                rpm       <= RPM_NUMERATOR / denominator;
                rpm_valid <= 1'b1;
            end
        end
    end
endmodule