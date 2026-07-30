`timescale 1ns/1ps

module tb_injector_timer;

    reg clk;
    reg rst;
    reg [31:0] open_time;
    reg start;

    wire out;
    wire executing;

    injector_timer #(
        .FREQ_HZ(50000000)
    ) dut (
        .clk(clk),
        .rst(rst),
        .open_time(open_time),
        .start(start),
        .out(out),
        .executing(executing)
    );

    // Clock de 50 MHz (20 ns)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        rst = 1;
        start = 0;
        open_time = 20;

        #40;
        rst = 0;

        // Pulso de 20 ns
        #20;
        start = 1;

        #40;
        start = 0;

        // Pulso de 60 ns
        open_time = 60;

        #100;
        start = 1;

        #40;
        start = 0;

        // Pulso de 100 ns
        open_time = 100;

        #100;
        start = 1;

        #40;
        start = 0;

        #200;

        $finish;
    end

    initial begin
        $dumpfile("injector_timer.vcd");
        $dumpvars(0, tb_injector_timer);
    end

    initial begin
        $monitor(
            "time=%0t ns | open_time=%0d ns | cycles=%0d | counter=%0d | start=%b | executing=%b | out=%b",
            $time,
            open_time,
            dut.open_time_cycles,
            dut.counter,
            start,
            executing,
            out
        );
    end

endmodule