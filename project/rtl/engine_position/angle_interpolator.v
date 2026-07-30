//==============================================================================
// Modulo: angle_interpolator
//
// Descricao:
// Estima continuamente a posicao angular do virabrequim entre dois dentes
// consecutivos da roda fonica.
//
// A saida utiliza ponto fixo de 16 bits:
//
//     360 graus = 65536 unidades
//
// Para uma roda 60-2, cada posicao possui 6 graus e corresponde a 1092
// unidades na aproximacao adotada atualmente.
//
// Formula:
//
// angle = tooth_number * ANGLE_PER_TOOTH
//       + time_since_tooth * ANGLE_PER_TOOTH / tooth_period
//
// tooth_period deve ser o periodo normal filtrado, e nao o intervalo triplo da
// falha. Dessa forma, o angulo continua avancando corretamente durante as duas
// posicoes sem dentes.
//==============================================================================

module angle_interpolator #(
    parameter integer ANGLE_BITS      = 16,
    parameter integer TIME_BITS       = 32,
    parameter integer ANGLE_PER_TOOTH = 1092
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire [15:0]           tooth_number,
    input  wire [TIME_BITS-1:0]  tooth_period,
    input  wire [TIME_BITS-1:0]  time_since_tooth,
    input  wire                  position_valid,

    output reg  [ANGLE_BITS-1:0] interpolated_angle,
    output reg                   angle_valid
);

    wire [63:0] tooth_number_extended;
    wire [63:0] time_since_tooth_extended;
    wire [63:0] base_angle;
    wire [63:0] offset_numerator;
    wire [63:0] interpolated_offset;
    wire [63:0] complete_angle;

    // Estende o numero do dente para 64 bits e evita overflow na multiplicacao.
    assign tooth_number_extended = {48'd0, tooth_number};

    // Estende o contador de tempo para 64 bits e preserva o valor sem sinal.
    assign time_since_tooth_extended = {{(64 - TIME_BITS){1'b0}}, time_since_tooth};

    // Calcula o angulo base correspondente ao inicio do dente atual.
    assign base_angle = tooth_number_extended * ANGLE_PER_TOOTH;

    // Calcula o numerador usado para obter o avanco angular entre os dentes.
    assign offset_numerator = time_since_tooth_extended * ANGLE_PER_TOOTH;

    // Converte o tempo decorrido em deslocamento angular dentro do dente atual.
    assign interpolated_offset = (tooth_period != 0) ? (offset_numerator / tooth_period) : 64'd0;

    // Soma o angulo base ao deslocamento interpolado desde o ultimo dente.
    assign complete_angle = base_angle + interpolated_offset;

    always @(posedge clk) begin
        if (rst) begin
            interpolated_angle <= 0;
            angle_valid        <= 1'b0;
        end
        else begin
            angle_valid <= 1'b0;

            if (position_valid && (tooth_period != 0)) begin
                // Os bits menos significativos implementam naturalmente o
                // retorno de 360 graus para zero.
                interpolated_angle <= complete_angle[ANGLE_BITS-1:0];
                angle_valid        <= 1'b1;
            end
        end
    end
endmodule