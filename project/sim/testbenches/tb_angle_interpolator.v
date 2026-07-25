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

angle_interpolator #(
    .ANGLE_BITS(16),
    .TIME_BITS(32),
    .TOOTH_ANGLE(6)
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
    tooth_period = 1000;
    time_since_tooth = 0;
    position_valid = 0;

    #50;

    rst = 0;
    position_valid = 1;

    for(i = 0; i < 58; i = i + 1)
    begin
        tooth_number = i;

        time_since_tooth = 0;
        #20;

        time_since_tooth = 250;
        #20;

        time_since_tooth = 500;
        #20;

        time_since_tooth = 750;
        #20;
    end

    position_valid = 0;

    #100;

    $finish;
end

always @(posedge clk)
begin
    if(angle_valid)
    begin
        $display(
            "time=%0t | tooth=%0d | elapsed=%0d | angle=%0d",
            $time,
            tooth_number,
            time_since_tooth,
            interpolated_angle
        );
    end
end

endmodule