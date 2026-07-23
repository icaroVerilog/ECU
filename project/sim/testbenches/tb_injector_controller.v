`timescale 1ns/1ps

module tb_injector_controller;

    reg clk;
    reg rst;
    reg injection_request;
    reg enable;
    reg [31:0] open_time;

    wire injector0_out;
    wire injector1_out;
    wire injector2_out;
    wire injector3_out;


    injector_controller dut (
        .clk(clk),
        .rst(rst),
        .injection_request(injection_request),
        .enable(enable),
        .open_time(open_time),

        .injector0_out(injector0_out),
        .injector1_out(injector1_out),
        .injector2_out(injector2_out),
        .injector3_out
        (injector3_out)
    );


    // Clock 50MHz
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end


    // Pulso de request
    task trigger_injection;
        begin
            @(posedge clk);
            injection_request = 1;

            @(posedge clk);
            injection_request = 0;
        end
    endtask


    initial begin

        rst = 1;
        enable = 0;
        injection_request = 0;
        open_time = 200;


        // ===================================
        // Caso 1 - Reset inicial
        // ===================================

        #100;

        rst = 0;
        enable = 1;


        // ===================================
        // Caso 2 - Pulso normal
        // Espera suficiente
        // ===================================

        $display("\nCASO 1 - Injecao normal");

        trigger_injection();

        #1000;


        // ===================================
        // Caso 3 - Dois pedidos muito proximos
        // Segundo deve ser ignorado
        // ===================================

        $display("\nCASO 2 - Pedidos durante execucao");

        trigger_injection();

        #50;

        trigger_injection();

        #1000;


        // ===================================
        // Caso 4 - Alta frequencia de pedidos
        // Simula RPM alto
        // ===================================

        $display("\nCASO 3 - Alta frequencia");

        repeat(10) begin
            trigger_injection();
            #100;
        end


        #1000;


        // ===================================
        // Caso 5 - Mudanca de tempo de abertura
        // ===================================

        $display("\nCASO 4 - Mudando open_time");

        open_time = 1000;

        trigger_injection();

        #2000;


        open_time = 50;

        trigger_injection();

        #500;



        // ===================================
        // Caso 6 - Disable
        // ===================================

        $display("\nCASO 5 - Disable");

        enable = 0;

        trigger_injection();

        #500;


        enable = 1;


        // ===================================
        // Caso 7 - Reset durante funcionamento
        // ===================================

        $display("\nCASO 6 - Reset durante pulso");

        open_time = 2000;

        trigger_injection();

        #200;

        rst = 1;

        #100;

        rst = 0;


        #2000;


        $display("\nSIMULACAO FINALIZADA");

        $finish;

    end


    initial begin
        $dumpfile("injector_controller.vcd");
        $dumpvars(0,tb_injector_controller);
    end


    initial begin
        $monitor(
            "t=%0t ns | req=%b | enable=%b | open=%0d ns | pair=%b | inj0=%b inj1=%b inj2=%b inj3=%b | exec=%b%b%b%b",
            $time,
            injection_request,
            enable,
            open_time,
            dut.injector_pair_start,
            injector0_out,
            injector1_out,
            injector2_out,
            injector3_out,
            dut.executing3,
            dut.executing2,
            dut.executing1,
            dut.executing0
        );
    end

endmodule