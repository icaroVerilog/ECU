`timescale 1ns/1ps

module tb_period_counter;

    //==========================================================================
    // Clock e sinais de entrada
    //==========================================================================

    reg clk;
    reg rst;
    reg tooth_rise;

    //==========================================================================
    // Saídas do DUT (Device Under Test - Dispositivo em Teste)
    //==========================================================================

    wire [31:0] tooth_period;
    wire        period_valid;

    //==========================================================================
    // Instância do módulo
    //==========================================================================

    period_counter dut (
        .clk(clk),
        .rst(rst),
        .tooth_rise(tooth_rise),
        .tooth_period(tooth_period),
        .period_valid(period_valid)
    );

    //==========================================================================
    // Clock de 50 MHz
    // Período = 20 ns
    //==========================================================================

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    //==========================================================================
    // Gera um pulso tooth_rise de um ciclo de clock
    //==========================================================================

    task pulse_tooth;
    begin
        @(posedge clk);
        tooth_rise <= 1'b1;

        @(posedge clk);
        tooth_rise <= 1'b0;
    end
    endtask

    //==========================================================================
    // Estímulos
    //==========================================================================

    initial begin

        rst        <= 1'b1;
        tooth_rise <= 1'b0;

        // Reset
        repeat (5) @(posedge clk);
        rst <= 1'b0;

        //==============================================================
        // Dentes normais
        //==============================================================

        repeat (100) @(posedge clk);
        pulse_tooth();

        repeat (100) @(posedge clk);
        pulse_tooth();

        repeat (100) @(posedge clk);
        pulse_tooth();

        repeat (100) @(posedge clk);
        pulse_tooth();

        //==============================================================
        // Simulação da falha de dois dentes (roda fônica 60-2)
        // O intervalo passa de 100 para 300 clocks.
        //==============================================================

        repeat (300) @(posedge clk);
        pulse_tooth();

        //==============================================================
        // Dentes normais novamente
        //==============================================================

        repeat (100) @(posedge clk);
        pulse_tooth();

        repeat (100) @(posedge clk);
        pulse_tooth();

        repeat (100) @(posedge clk);
        pulse_tooth();

        repeat (100) @(posedge clk);
        pulse_tooth();

        // Aguarda alguns ciclos antes de finalizar
        repeat (20) @(posedge clk);

        $finish;

    end

    //==========================================================================
    // Monitor
    //==========================================================================

    initial begin

        $display("------------------------------------------------");
        $display(" Time(ns) | Period (clocks) | Valid");
        $display("------------------------------------------------");

        forever begin
            @(posedge clk);

            if (period_valid) begin
                $display("%8t | %15d |   %b",
                         $time,
                         tooth_period,
                         period_valid);
            end
        end

    end

    //==========================================================================
    // Arquivo VCD para GTKWave
    //==========================================================================

    initial begin
        $dumpfile("tb_period_counter.vcd");
        $dumpvars(0, tb_period_counter);
    end

endmodule