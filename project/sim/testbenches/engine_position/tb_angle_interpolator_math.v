`timescale 1ns/1ps

//==============================================================================
// Testbench: tb_angle_interpolator_math
//
// Objetivo:
//
// Validar a implementação matemática do módulo angle_interpolator.
//
// Este testbench aplica valores conhecidos de:
//
// - tooth_number;
// - tooth_period;
// - time_since_tooth;
//
// e verifica se a posição angular calculada corresponde ao valor esperado.
//
// O objetivo principal é validar:
//
// - a equação de interpolação linear;
// - a representação angular em ponto fixo;
// - a conversão entre tempo decorrido e deslocamento angular;
// - o comportamento nos pontos inicial, intermediário e final do intervalo
//   entre dois dentes.
//
// Este teste não simula a passagem real do tempo do motor. Os valores de
// time_since_tooth são aplicados diretamente para validar a matemática.
//
// Representação angular:
//
// 360° = 65536 unidades
//
// Para uma roda fônica 60-2:
//
// Δθ = 6°
//
// ANGLE_PER_TOOTH:
//
// 6 * 65536 / 360 = 1092
//
// Equação:
//
// θ = θ_base + (time_since_tooth * ANGLE_PER_TOOTH) / tooth_period
//
// Exemplo esperado:
//
// 0%   do período -> 0°
// 25%  do período -> 1,5°
// 50%  do período -> 3°
// 75%  do período -> 4,5°
// 100% do período -> 6°
//
//==============================================================================


module tb_angle_interpolator_math;

reg clk;
reg rst;
reg [15:0] tooth_number;
reg [31:0] tooth_period;
reg [31:0] time_since_tooth;
reg position_valid;

wire [15:0] interpolated_angle;
wire angle_valid;

real angle_deg;

angle_interpolator #(
    .ANGLE_BITS(16),
    .TIME_BITS(32),
    .ANGLE_PER_TOOTH(1092)
) dut (
    .clk(clk),
    .rst(rst),
    .tooth_number(tooth_number),
    .tooth_period(tooth_period),
    .time_since_tooth(time_since_tooth),
    .position_valid(position_valid),
    .interpolated_angle(interpolated_angle),
    .angle_valid(angle_valid)
);


always #10 clk = ~clk;


task test_angle;
    input [15:0] tooth;
    input [31:0] elapsed;

    begin
        tooth_number = tooth;
        time_since_tooth = elapsed;

        #20;

        angle_deg = (interpolated_angle * 360.0) / 65536.0;

        $display(
            "tooth=%0d | elapsed=%0d | raw=%0d | angle=%0.3f deg",
            tooth_number,
            time_since_tooth,
            interpolated_angle,
            angle_deg
        );
    end
endtask


initial begin

    $dumpfile("angle_interpolator_math.vcd");
    $dumpvars(0,tb_angle_interpolator_math);

    clk = 0;
    rst = 1;

    tooth_number = 0;
    tooth_period = 103448; // 500 RPM
    time_since_tooth = 0;
    position_valid = 0;


    #50;

    rst = 0;
    position_valid = 1;


    // Teste de linearidade do primeiro dente
    test_angle(0,0);
    test_angle(0,25862);
    test_angle(0,51724);
    test_angle(0,77586);
    test_angle(0,103448);


    // Teste com deslocamento angular da roda
    test_angle(10,0);
    test_angle(10,51724);


    // Teste próximo ao final da roda
    test_angle(57,0);
    test_angle(57,103448);


    position_valid = 0;

    #100;

    $finish;

end


endmodule