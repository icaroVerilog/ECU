//==============================================================================
// Módulo: angle_interpolator
//
// Descrição:
// Estima continuamente a posição angular do virabrequim entre dois dentes
// consecutivos da roda fônica.
//
// O módulo utiliza como referência:
//
// - a posição angular do último dente detectado;
// - o período medido entre os dois últimos dentes;
// - o tempo decorrido desde a última borda de subida do sensor CKP.
//
// Assume-se que a velocidade angular permanece aproximadamente constante
// durante o intervalo entre dois dentes consecutivos. Dessa forma, a posição
// angular pode ser estimada por interpolação linear.
//
// Exemplo para uma roda 60-2:
//
//            6°
// Dente ---------------- Dente
// 150°                  156°
//
// Se metade do tempo entre os dois dentes já transcorreu, estima-se que o
// virabrequim tenha percorrido aproximadamente metade da distância angular,
// resultando em:
//
// 150° + 3° = 153°
//
// A saída é fornecida em graus escalados (ANGLE_SCALE), permitindo aumentar a
// resolução angular sem utilizar números em ponto flutuante.
//
// Nesta primeira implementação, a interpolação é realizada por meio de uma
// divisão inteira. Caso necessário, esse cálculo poderá ser otimizado em
// versões futuras utilizando técnicas mais adequadas para FPGA, como
// multiplicação por fatores pré-calculados ou aritmética em ponto fixo.
//==============================================================================

// module angle_interpolator #(
//     parameter TOTAL_TEETH = 60,
//     parameter ANGLE_SCALE = 10,

//     localparam ANGLE_PER_TOOTH = (360 * ANGLE_SCALE) / TOTAL_TEETH,
//     localparam ANGLE_WIDTH = $clog2(360 * ANGLE_SCALE)
// )(
//     input wire clk,
//     input wire rst,

//     input wire tooth_rise,

//     input wire [31:0] tooth_period,
//     input wire tooth_period_valid,

//     input wire [ANGLE_WIDTH-1:0] crankshaft_angle,
//     input wire position_valid,

//     output reg [ANGLE_WIDTH-1:0] interpolated_angle,
//     output reg interpolated_valid
// );

//     reg [31:0] elapsed_time;
//     reg [31:0] last_tooth_period;

//     reg [ANGLE_WIDTH:0] base_angle;
//     reg [ANGLE_WIDTH:0] increment;
//     reg [ANGLE_WIDTH:0] angle_temp;

//     always @(posedge clk) begin
//         if (rst) begin
//             elapsed_time <= 0;
//             last_tooth_period <= 0;
//             interpolated_angle <= 0;
//             interpolated_valid <= 0;

//         end
//         else begin

//             /*
//              * Antes do sincronismo ser estabelecido, a posição
//              * angular não é conhecida e, portanto, não é possível
//              * realizar a interpolação.
//              */
//             if (!position_valid) begin
//                 elapsed_time <= 0;
//                 interpolated_angle <= 0;
//                 interpolated_valid <= 0;

//             end
//             else begin

//                 interpolated_valid <= 1;

//                 /*
//                  * Armazena o último período válido medido entre
//                  * dois dentes consecutivos da roda fônica.
//                  */
//                 if (tooth_period_valid) begin
//                     last_tooth_period <= tooth_period;
//                 end

//                 /*
//                  * Atualiza o tempo decorrido desde o último dente.
//                  */
//                 if (tooth_rise) begin
//                     elapsed_time <= 0;
//                 end
//                 else begin
//                     elapsed_time <= elapsed_time + 1;
//                 end

//                 /*
//                  * Calcula continuamente a posição angular estimada
//                  * entre dois dentes consecutivos.
//                  */
//                 base_angle = crankshaft_angle * ANGLE_SCALE;

//                 if (last_tooth_period != 0) begin
//                     increment =
//                         (elapsed_time * ANGLE_PER_TOOTH) /
//                         last_tooth_period;
//                 end
//                 else begin
//                     increment = 0;
//                 end

//                 angle_temp = base_angle + increment;

//                 /*
//                  * Durante a transição entre o último dente físico
//                  * (354°) e a referência da próxima volta (0°),
//                  * permite que a interpolação alcance 360° antes
//                  * de reiniciar em zero.
//                  */
//                 if ((crankshaft_angle == 0) && (increment != 0)) begin
//                     interpolated_angle <= (360 * ANGLE_SCALE) + increment;
//                 end
//                 else begin
//                     interpolated_angle <= angle_temp[ANGLE_WIDTH-1:0];
//                 end

//             end
//         end
//     end
// endmodule


module angle_interpolator #(
    parameter ANGLE_BITS = 16,
    parameter TIME_BITS = 32,
    parameter TOOTH_ANGLE = 6
)(
    input wire clk,
    input wire rst,
    input wire [15:0] tooth_number,
    input wire [TIME_BITS-1:0] tooth_period,
    input wire [TIME_BITS-1:0] time_since_tooth,
    input wire position_valid,
    
    output reg [ANGLE_BITS-1:0] interpolated_angle,
    output reg angle_valid
);

    reg [31:0] angle_base;
    reg [31:0] interpolation;

    always @(posedge clk) begin
        if (rst) begin
            interpolated_angle <= 0;
            angle_valid <= 0;
        end
        else begin
            angle_valid <= 0;
            if (position_valid) begin
                angle_base = tooth_number * TOOTH_ANGLE;
                if (tooth_period != 0) begin
                    interpolation = (time_since_tooth * TOOTH_ANGLE) / tooth_period;
                end
                else begin
                    interpolation = 0;
                end

                interpolated_angle <= angle_base + interpolation;
                angle_valid <= 1;
            end
        end
    end
endmodule