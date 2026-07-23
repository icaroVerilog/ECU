`timescale 1ns/1ps

module tb_pwm_generator;

    reg clk;
    reg reset;
    wire out;

    pwm_generator #(
        .FREQ_HZ(50000000),
        .INITIAL_WIDTH(20),
        .INITIAL_PERIOD(100),
        .STEP_CYCLES(1)
    ) dut (
        .clk(clk),
        .reset(reset),
        .out(out)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;   // Clock de 50 MHz (20 ns)
    end

    initial begin
        reset = 1;

        #40;
        reset = 0;

        #3000;

        $finish;
    end

    initial begin
        $dumpfile("tb_pwm_generator.vcd");
        $dumpvars(0, tb_pwm_generator);
    end

endmodule