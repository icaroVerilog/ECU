`timescale 1ns/1ps

//==============================================================================
// Testbench: tb_angle_interpolator_realtime
//
// Objetivo:
//
// Validar o comportamento temporal do módulo angle_interpolator simulando a
// operação real de uma FPGA conectada ao sensor CKP (Crankshaft Position).
//
// Diferentemente do teste matemático, este testbench gera o sinal
// time_since_tooth através de um contador incrementado a cada ciclo de clock.
//
// O objetivo principal é validar:
//
// - evolução contínua da posição angular entre dentes;
// - sincronismo entre contador de tempo e interpolação angular;
// - comportamento durante uma rotação simulada;
// - ausência de descontinuidades na transição entre dentes.
//
// Modelo de funcionamento:
//
// Detecção do dente:
//
//          tooth
//            |
//            v
// time_since_tooth = 0
//            |
//            v
// contador incrementa a cada clock
//            |
//            v
// angle_interpolator calcula a posição angular
//            |
//            v
// próximo dente detectado
//            |
//            v
// contador reinicia
//
// Condições:
//
// Clock FPGA:
//
// 50 MHz
//
// Período do clock:
//
// 20 ns
//
// Velocidade simulada:
//
// 500 RPM
//
// Período entre dentes:
//
// tooth_period = 103448 ciclos
//
// Tempo entre dentes:
//
// 103448 * 20 ns = 2,06896 ms
//
//==============================================================================


module tb_angle_interpolator_realtime;

reg clk;
reg rst;

reg [15:0] tooth_number;
reg [31:0] tooth_period;
reg [31:0] time_since_tooth;
reg position_valid;

wire [15:0] interpolated_angle;
wire angle_valid;

real angle_deg;


parameter TOOTH_PERIOD = 103448;


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


// Contador equivalente ao hardware real
always @(posedge clk)
begin
    if(rst)
    begin
        time_since_tooth <= 0;
    end
    else if(position_valid)
    begin
        if(time_since_tooth < TOOTH_PERIOD)
            time_since_tooth <= time_since_tooth + 1;
        else
            time_since_tooth <= 0;
    end
end


integer i;


initial begin

    $dumpfile("angle_interpolator_realtime.vcd");
    $dumpvars(0,tb_angle_interpolator_realtime);


    clk = 0;
    rst = 1;

    tooth_number = 0;
    tooth_period = TOOTH_PERIOD;
    time_since_tooth = 0;
    position_valid = 0;


    #50;

    rst = 0;
    position_valid = 1;


    // Simula alguns dentes da roda fônica
    for(i = 0; i < 3; i = i + 1)
    begin

        wait(time_since_tooth == TOOTH_PERIOD);

        tooth_number = tooth_number + 1;

        time_since_tooth = 0;

    end


    position_valid = 0;


    #100;

    $finish;

end


always @(posedge clk)
begin

    if(angle_valid)
    begin

        angle_deg =
        (interpolated_angle * 360.0) / 65536.0;


        $display(
            "time=%0t ns | tooth=%0d | elapsed=%0d | raw=%0d | angle=%0.3f deg",
            $time,
            tooth_number,
            time_since_tooth,
            interpolated_angle,
            angle_deg
        );

    end

end


endmodule