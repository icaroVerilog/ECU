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


module angle_interpolator #(
    parameter ANGLE_BITS = 16,
    parameter TIME_BITS = 32,
    parameter ANGLE_PER_TOOTH = 1092
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

    always @(posedge clk) begin
        if (rst) begin
            interpolated_angle <= 0;
            angle_valid <= 0;
        end
        else begin
            angle_valid <= 0;

            if (position_valid) begin
                if (tooth_period != 0) begin
                    interpolated_angle <= (tooth_number * ANGLE_PER_TOOTH) + ((time_since_tooth * ANGLE_PER_TOOTH) / tooth_period);
                end
                else begin
                    interpolated_angle <= 0;
                end

                angle_valid <= 1;
            end
        end
    end
endmodule