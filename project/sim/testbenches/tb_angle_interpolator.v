`timescale 1ns/1ps

module tb_angle_interpolator;

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

integer i;

initial begin
    $dumpfile("angle_interpolator.vcd");
    $dumpvars(0,tb_angle_interpolator);

    clk = 0;
    rst = 1;

    tooth_number = 0;
    tooth_period = 103448; // 500 RPM
    time_since_tooth = 0;
    position_valid = 0;

    #50;

    rst = 0;
    position_valid = 1;

    // Simula os 58 dentes físicos de uma roda 60-2
    for(i = 0; i < 58; i = i + 1)
    begin
        tooth_number = i;

        // 0 graus dentro do dente
        time_since_tooth = 0;
        #516970;

        // 1.5 graus
        time_since_tooth = 25862;
        #516970;

        // 3 graus
        time_since_tooth = 51724;
        #516970;

        // 4.5 graus
        time_since_tooth = 77586;
        #516970;

        // final do dente (6 graus)
        time_since_tooth = 103448;
        #516970;
    end

    position_valid = 0;

    #100;

    $finish;
end

always @(posedge clk)
begin
    if(angle_valid)
    begin
        angle_deg = (interpolated_angle * 360.0) / 65536.0;

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